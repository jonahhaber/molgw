!=========================================================================
! This file is part of MOLGW.
! Author: Fabien Bruneval
!
! This module contains
! the methods and data for Effective Core Potentials (ECP)
!
!=========================================================================
module m_ecp
  use m_definitions
  use m_string_tools, only: capitalize,append_to_list,orbital_momentum_name,orbital_momentum_number
  use m_warning, only: die,issue_warning
  use m_elements
  use ISO_FORTRAN_ENV, only: IOSTAT_END
 
 
  integer,protected                :: nelement_ecp
  integer,protected,allocatable    :: element_ecp(:)
 
  type effective_core_potential
    integer              :: nelec          ! number of core electrons
    integer              :: necp           ! number of projectors
    integer,allocatable  :: lk(:)          ! angular momentum of the projector (-1 stands for local component)
    integer,allocatable  :: nk(:)          ! r**(nk-2)
    real(dp),allocatable :: dk(:)          ! dk coefficient
    real(dp),allocatable :: zetak(:)       ! zetak coefficient (gaussian exponent)
  end type
 
  type(effective_core_potential),allocatable :: ecp(:)
 
  !
  ! Grid quality description
  integer,protected      :: nradial_ecp,nangular_ecp


contains


!=========================================================================
subroutine init_ecp(ecp_elements,ecp_path,ecp_name,ecp_level_in)
  implicit none
 
  character(len=*),intent(in) :: ecp_elements
  character(len=*),intent(in) :: ecp_path
  character(len=*),intent(in) :: ecp_name
  integer,intent(in)          :: ecp_level_in
  !=====
  character(len=132) :: string,ecp_filename
  character(len=2)   :: element
  character(len=5)   :: amc
  integer :: ecpfile
  integer :: ilen,inextblank,ielement_ecp,iecp
  logical :: file_exists
  !=====
 
  !
  ! First parse the ecp_elements line
  !
  ilen = LEN(TRIM(ecp_elements))
 
  ! ecp_elements is empty, no ECP needs to be setup
  if( ilen == 0 ) return
 
  string = ecp_elements
  write(stdout,'(/,1x,a)') 'Reading ECP element list'
 
  !
  ! Set up the integration grid
  select case(ecp_level_in)
  case(low)       ! accuracy not guaranted, just for quick test runs
    nradial_ecp     =  12
    nangular_ecp    =   6
  case(medium)
    nradial_ecp     =  20
    nangular_ecp    =  26
  case(high)
    nradial_ecp     =  35
    nangular_ecp    =  38
  case(very_high) ! almost perfect potentials
    nradial_ecp     =  50
    nangular_ecp    = 110
  case(insane)    ! overdoing a lot
    nradial_ecp     = 200
    nangular_ecp    = 434
  case default
    call die('integration quality not recognized')
  end select
  write(stdout,'(1x,a,i5,2x,i5)') 'ECP are integrated numerically with a grid (radial,angular): ',nradial_ecp,nangular_ecp
 
 
  do while( ilen > 0 )
    string = ADJUSTL(string)
    inextblank = INDEX(string,' ')
 
    call append_to_list(element_number(string(1:inextblank-1)),element_ecp)
 
    string = string(inextblank+1:)
    ilen = LEN(TRIM(string))
 
  enddo
 
  nelement_ecp = SIZE(element_ecp)
  allocate(ecp(nelement_ecp))
 
 
  !
  ! Second, read the ECP parameters from ECP file
  !
  do ielement_ecp=1,nelement_ecp
    element = element_name(REAL(element_ecp(ielement_ecp),dp))
    write(stdout,'(1x,a,a)') 'ECP for element: ',element
 
    ecp_filename = TRIM(ecp_path)//'/'//TRIM(ADJUSTL(element))//'_'//TRIM(ecp_name)
    inquire(file=TRIM(ecp_filename),exist=file_exists)
    if( .NOT. file_exists ) then
      write(stdout,'(1x,a,a)') 'Looking for file ',TRIM(ecp_filename)
      write(stdout,'(1x,a)')   'Remember the basis directory path is obtained (by priority order) from:'
      write(stdout,'(1x,a)')   '  1. the input variable basis_path'
      write(stdout,'(1x,a)')   '  2. the environment variable MOLGW_BASIS_PATH'
      write(stdout,'(1x,a)')   '  3. the location of the sources'
      call die('init_ecp: ECP file not found')
    endif
    open(newunit=ecpfile,file=TRIM(ecp_filename),status='old',action='read')
 
    call read_ecp_file(ecpfile,element,ecp(ielement_ecp))
    close(ecpfile)
 
    write(stdout,'(6x,a,i3)') 'Core electrons ',ecp(ielement_ecp)%nelec
    write(stdout,'(6x,a)') 'l_k      n_k       zeta_k          d_k  '
 
    do iecp=1,ecp(ielement_ecp)%necp
      if( ecp(ielement_ecp)%lk(iecp) == -1 ) then
        amc = 'local'
      else
        amc = orbital_momentum_name(ecp(ielement_ecp)%lk(iecp))
      endif
      write(stdout,'(6x,a,3x,i3,2(2x,f14.6))') &
                          amc, &
                          ecp(ielement_ecp)%nk(iecp), &
                          ecp(ielement_ecp)%zetak(iecp), &
                          ecp(ielement_ecp)%dk(iecp)
    enddo
 
  enddo



end subroutine init_ecp


!=========================================================================
subroutine read_ecp_file(ecpunit,element,ecpi)
  implicit none
 
  integer,intent(in)                           :: ecpunit
  character(len=2),intent(in)                  :: element
  type(effective_core_potential),intent(inout) :: ecpi
  !=====
  integer            :: iline,i1,i2,istat
  character(len=132) :: line,amc
  integer            :: read_n
  real(dp)           :: read_zeta,read_d
  logical            :: end_of_file
  !=====
 
  ! Reading an ECP file in NWCHEM format
 
  end_of_file = .FALSE.
  iline = 0
  line='_____'   ! Five underscores '_____' means 'advance to next line'
  do while(.NOT. end_of_file)
    iline = iline + 1
    if( line(1:5) == '_____' ) then
      read(ecpunit,'(a)',iostat=istat) line
      if( istat == IOSTAT_END ) then
        end_of_file = .TRUE.
        exit
      endif
    endif
    line = ADJUSTL(line)
 
    ! Remove comments if any
    if( line(1:1) == '#' ) then
      line='_____'
      cycle
    endif
 
    ! ECP and END should not be interpreted
    if( capitalize(line(1:3)) == 'ECP' .OR. capitalize(line(1:3)) == 'END' ) then
      line='_____'
      cycle
    endif
    i1 = INDEX(line,' ')
 
    if( line(1:i1-1) /= TRIM(element) .AND. capitalize(line(1:i1-1)) /= TRIM(ADJUSTL(element)) ) then
      write(stdout,*) 'ECP file should only contain information about element '//TRIM(ADJUSTL(element))
      write(stdout,*) 'While '//line(1:i1-1)//' was found'
      call die('ECP file reading problem')
    endif
 
    line = ADJUSTL(line(i1+1:))
 
    i2 = INDEX(line,' ')
    amc = capitalize(line(1:i2-1))
    if( amc == 'NELEC' ) then
      read(line(i2+1:),'(i10)') ecpi%nelec
      line='_____'
      cycle
    endif
    if(      amc == 'UL'  &
        .OR. amc == 'S'   &
        .OR. amc == 'P'   &
        .OR. amc == 'D'   &
        .OR. amc == 'F'   &
        .OR. amc == 'G'   &
        .OR. amc == 'H'   ) then
      istat = 0
      do while(istat == 0)
        read(ecpunit,'(a)',iostat=istat) line
        if( istat == IOSTAT_END ) then
          end_of_file = .TRUE.
          exit
        endif
        read(line,*,iostat=istat) read_n,read_zeta,read_d
 
        ! For the time being, only code ECP with no local potential
        if( istat == 0 ) then
          if( amc == 'UL' ) then
            call append_to_list(-1,ecpi%lk)
          else
            call append_to_list(orbital_momentum_number(amc),ecpi%lk)
          endif
          call append_to_list(read_n,ecpi%nk)
          call append_to_list(read_zeta,ecpi%zetak)
          call append_to_list(read_d,ecpi%dk)
        endif
      enddo
    else
      write(stdout,*) capitalize(line(1:i2-1)),line(1:i2-1)
      call die('problem reading ECP file')
    endif
 
 
  enddo
 
 
  ecpi%necp = SIZE(ecpi%nk)


end subroutine read_ecp_file


!=========================================================================
end module m_ecp
!=========================================================================
