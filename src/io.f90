!=========================================================================
! This file is part of MOLGW.
! Author: Fabien Bruneval
!
! This file contains
! the procedures for input and outputs
!
!=========================================================================
subroutine header()
#ifdef FORTRAN2008
 use,intrinsic :: iso_fortran_env, only: compiler_version,compiler_options
#endif
 use m_definitions
 use m_mpi
 use m_warning,only: issue_warning
 use m_tools,only: orbital_momentum_name
 use m_libint_tools,only: libint_init
 implicit none

#ifdef _OPENMP
 integer,external :: OMP_get_max_threads
#endif
 character(len=40)   :: git_sha
 integer             :: values(8) 
 character(len=1024) :: chartmp
 integer             :: nchar,kchar,lchar
!=====
! variables used to call C
 integer(C_INT)      :: ammax
 logical(C_BOOL)     :: has_onebody,has_gradient
!=====

! Here we call the fortran code that was generated by the python script
! Any new variable should be added through the python script
#include "git_sha.f90"
 
!=====

 write(stdout,'(1x,70("="))') 
 write(stdout,'(/,/,12x,a,/)') 'Welcome to the fascinating world of MOLGW'
 write(stdout,'(24x,a)')       'version 1.C'
 write(stdout,'(/,/,1x,70("="))') 

 write(stdout,'(/,a,a,/)') ' MOLGW commit git SHA: ',git_sha
#ifdef FORTRAN2008
 write(stdout,'(1x,a,a)')    'compiled with ',compiler_version()
 write(stdout,'(1x,a)')      'with options: '
 chartmp = compiler_options()
 nchar = LEN(TRIM(chartmp))
 kchar = 1
 lchar = 0
 do 
   lchar = SCAN(chartmp(kchar:nchar),' ')
   if( lchar == 0 ) exit
   write(stdout,'(6x,a,a)') 'FCOPT  ',chartmp(kchar:kchar+lchar-1)
   kchar = kchar + lchar
 enddo
 write(stdout,*)
#endif


 call date_and_time(VALUES=values)

 write(stdout,'(a,i2.2,a,i2.2,a,i4.4)') ' Today is ',values(2),'/',values(3),'/',values(1)
 write(stdout,'(a,i2.2,a,i2.2)')        ' It is now ',values(5),':',values(6)
 select case(values(5))
 case(03,04,05,06,07)
   write(stdout,*) 'And it is too early to work. Go back to sleep'
 case(22,23,00,01,02)
   write(stdout,*) 'And it is too late to work. Go to bed and have a sleep'
 case(12,13)
   write(stdout,*) 'Go and get some good food'
 case(17)
   write(stdout,*) 'Dont forget to go and get the kids'
 case default
   write(stdout,*) 'And it is perfect time to work'
 end select


 write(stdout,'(/,1x,a)') 'Linking options:'
#ifdef HAVE_LIBXC
!#ifndef LIBXC_SVN
! call xc_f90_version(values(1),values(2))
! write(chartmp,'(i2,a,i2)') values(1),'.',values(2)
!#else
! call xc_f90_version(values(1),values(2),values(3))
! write(chartmp,'(i2,a,i2,a,i2)') values(1),'.',values(2),'.',values(3)
!#endif
! write(stdout,*) 'LIBXC version '//TRIM(chartmp)
 write(stdout,*) 'Running with LIBXC'
#endif
#ifdef _OPENMP
 write(msg,'(i6)') OMP_get_max_threads()
 msg='OPENMP option is activated with threads number'//msg
 call issue_warning(msg)
#endif
#if defined HAVE_MPI && defined HAVE_SCALAPACK
 write(stdout,*) 'Running with MPI'
 write(stdout,*) 'Running with SCALAPACK'
#endif
#if defined(HAVE_MPI) && !defined(HAVE_SCALAPACK)
 call die('Code compiled with SCALAPACK, but without MPI. This is not permitted')
#endif
#if !defined(HAVE_MPI) && defined(HAVE_SCALAPACK)
 call die('Code compiled with MPI, but without SCALAPACK. This is not permitted')
#endif

 ! LIBINT details
 call libint_init(ammax,has_onebody,has_gradient)
 write(stdout,'(1x,a)')        'Running with LIBINT (to calculate the Coulomb integrals)'
 write(stdout,'(6x,a,i5,3x,a)') 'max angular momentum handled by your LIBINT compilation: ', &
                                ammax,orbital_momentum_name(ammax)
#ifdef HAVE_LIBINT_ONEBODY
 if( .NOT. has_onebody ) &
   call die('MOLGW compiled with LIBINT one-body terms, however the LIBINT compilation does not calculate the one-body terms')
 if( .NOT. has_gradient ) &
   call die('LIBINT compilation does not have the first derivative')
 write(stdout,'(1x,a)') 'Using LIBINT for the one-body parts of the Hamiltonian as well'
#endif
 write(stdout,*)
 write(stdout,*)


end subroutine header


!=========================================================================
subroutine dump_out_occupation(title,nstate,nspin,occupation)
 use m_definitions
 use m_mpi
 implicit none
 character(len=*),intent(in) :: title
 integer,intent(in)          :: nstate,nspin
 real(dp),intent(in)         :: occupation(nstate,nspin)
!=====
 integer :: ihomo
 integer :: istate,ispin
!=====

 write(stdout,'(/,1x,a)') TRIM(title)

 if( nspin == 2 ) then
   write(stdout,'(a)') '           spin 1       spin 2 '
 endif
 do istate=1,nstate
   if( ANY(occupation(istate,:) > 0.001_dp) ) ihomo = istate 
 enddo

 do istate=MAX(1,ihomo-5),MIN(ihomo+5,nstate)
   write(stdout,'(1x,i3,2(2(1x,f12.5)),2x)') istate,occupation(istate,:)
 enddo
 write(stdout,*)

end subroutine dump_out_occupation


!=========================================================================
subroutine dump_out_energy(title,nstate,nspin,occupation,energy)
 use m_definitions
 use m_mpi
 implicit none
 character(len=*),intent(in) :: title
 integer,intent(in)          :: nstate,nspin
 real(dp),intent(in)         :: occupation(nstate,nspin),energy(nstate,nspin)
!=====
 integer,parameter :: MAXSIZE=300
!=====
 integer  :: istate,ispin
 real(dp) :: spin_fact
!=====

 spin_fact = REAL(-nspin+3,dp)

 write(stdout,'(/,1x,a)') TRIM(title)

 if(nspin==1) then
   write(stdout,'(a)') '   #       (Ha)         (eV)      '
 else
   write(stdout,'(a)') '   #              (Ha)                      (eV)      '
   write(stdout,'(a)') '           spin 1       spin 2       spin 1       spin 2'
 endif
 do istate=1,MIN(nstate,MAXSIZE)
   select case(nspin)
   case(1)
     write(stdout,'(1x,i3,2(1x,f12.5),4x,f8.4)') istate,energy(istate,:),energy(istate,:)*Ha_eV,occupation(istate,:)
   case(2)
     write(stdout,'(1x,i3,2(2(1x,f12.5)),4x,2(f8.4,2x))') istate,energy(istate,:),energy(istate,:)*Ha_eV,occupation(istate,:)
   end select
   if(istate < nstate) then
     if( ANY( occupation(istate+1,:) < spin_fact/2.0_dp .AND. occupation(istate,:) > spin_fact/2.0 ) ) then 
        if(nspin==1) then
          write(stdout,'(a)') '  -----------------------------'
        else
          write(stdout,'(a)') '  -------------------------------------------------------'
        endif
     endif
   endif
 enddo

 write(stdout,*)

end subroutine dump_out_energy


!=========================================================================
subroutine dump_out_matrix(print_matrix,title,n,nspin,matrix)
 use m_definitions
 use m_mpi
 implicit none
 logical,intent(in)          :: print_matrix       
 character(len=*),intent(in) :: title
 integer,intent(in)          :: n,nspin
 real(dp),intent(in)         :: matrix(n,n,nspin)
!=====
 integer,parameter :: MAXSIZE=25
!=====
 integer :: i,ispin
!=====

 if( .NOT. print_matrix ) return

 write(stdout,'(/,1x,a)') TRIM(title)

 do ispin=1,nspin
   if(nspin==2) then
     write(stdout,'(a,i1)') ' spin polarization # ',ispin
   endif
   do i=1,MIN(n,MAXSIZE)
     write(stdout,'(1x,i3,100(1x,f12.5))') i,matrix(i,1:MIN(n,MAXSIZE),ispin)
   enddo
   write(stdout,*)
 enddo
 write(stdout,*)

end subroutine dump_out_matrix


!=========================================================================
subroutine output_new_homolumo(calculation_name,nstate,occupation,energy,istate_min,istate_max)
 use m_definitions
 use m_mpi
 use m_inputparam,only: nspin,spin_fact
 implicit none

 character(len=*),intent(in) :: calculation_name
 integer,intent(in)          :: nstate,istate_min,istate_max
 real(dp),intent(in)         :: occupation(nstate,nspin),energy(nstate,nspin)
!=====
 real(dp) :: ehomo_tmp,elumo_tmp
 real(dp) :: ehomo(nspin),elumo(nspin)
 integer  :: ispin,istate
!=====

 do ispin=1,nspin
   ehomo_tmp=-HUGE(1.0_dp)
   elumo_tmp= HUGE(1.0_dp)

   do istate=istate_min,istate_max

     if( occupation(istate,ispin)/spin_fact > completely_empty ) then
       ehomo_tmp = MAX( ehomo_tmp , energy(istate,ispin) )
     endif

     if( occupation(istate,ispin)/spin_fact < 1.0_dp - completely_empty ) then
       elumo_tmp = MIN( elumo_tmp , energy(istate,ispin) )
     endif

   enddo

   ehomo(ispin) = ehomo_tmp
   elumo(ispin) = elumo_tmp

 enddo


 write(stdout,*)
 if( ALL( ehomo(:) > -1.0e6 ) ) then
   write(stdout,'(1x,a,1x,a,2(3x,f12.6))') TRIM(calculation_name),'HOMO energy    (eV):',ehomo(:) * Ha_eV
 endif
 if( ALL( elumo(:) <  1.0e6 ) ) then
   write(stdout,'(1x,a,1x,a,2(3x,f12.6))') TRIM(calculation_name),'LUMO energy    (eV):',elumo(:) * Ha_eV
 endif
 if( ALL( ehomo(:) > -1.0e6 ) .AND. ALL( elumo(:) <  1.0e6 ) ) then
   write(stdout,'(1x,a,1x,a,2(3x,f12.6))') TRIM(calculation_name),'HOMO-LUMO gap  (eV):',( elumo(:)-ehomo(:) ) * Ha_eV
 endif
 write(stdout,*)


end subroutine output_new_homolumo


!=========================================================================
subroutine mulliken_pdos(nstate,basis,s_matrix,c_matrix,occupation,energy)
 use m_definitions
 use m_mpi
 use m_inputparam, only: nspin
 use m_atoms
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: s_matrix(basis%nbf,basis%nbf)
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
 real(dp),intent(in)        :: occupation(nstate,nspin),energy(nstate,nspin)
!=====
 integer                    :: ibf,ibf_cart,li,ni,ni_cart
 integer                    :: natom1,natom2,istate,ispin
 logical                    :: file_exists
 integer                    :: pdosfile
 real(dp)                   :: proj_state_i(0:basis%ammax),proj_charge
 real(dp)                   :: cs_vector_i(basis%nbf)
 integer                    :: iatom_ibf(basis%nbf)
 integer                    :: li_ibf(basis%nbf)
!=====

 write(stdout,*)
 write(stdout,*) 'Projecting wavefunctions on selected atoms'
 inquire(file='manual_pdos',exist=file_exists)
 if(file_exists) then
   write(stdout,*) 'Opening file:','manual_pdos'
   open(newunit=pdosfile,file='manual_pdos',status='old')
   read(pdosfile,*) natom1,natom2
   close(pdosfile)
 else
   natom1=1
   natom2=1
 endif
 write(stdout,'(1x,a,i5,2x,i5)') 'Range of atoms considered: ',natom1,natom2

 ibf_cart = 1
 ibf      = 1
 do while(ibf_cart<=basis%nbf_cart)
   li      = basis%bf(ibf_cart)%am
   ni_cart = number_basis_function_am('CART',li)
   ni      = number_basis_function_am(basis%gaussian_type,li)

   iatom_ibf(ibf:ibf+ni-1) = basis%bf(ibf_cart)%iatom
   li_ibf(ibf:ibf+ni-1) = li

   ibf      = ibf      + ni
   ibf_cart = ibf_cart + ni_cart
 enddo
 

 write(stdout,'(1x,a)') '==========================================='
 write(stdout,'(1x,a)') 'spin state  energy(eV)  Mulliken proj. total        proj s         proj p      proj d ... '
 proj_charge = 0.0_dp
 do ispin=1,nspin
   do istate=1,nstate
     proj_state_i(:) = 0.0_dp

     cs_vector_i(:) = MATMUL( c_matrix(:,istate,ispin) , s_matrix(:,:) )

     do ibf=1,basis%nbf
       if( iatom_ibf(ibf) >= natom1 .AND. iatom_ibf(ibf) <= natom2 ) then
         li = li_ibf(ibf)
         proj_state_i(li) = proj_state_i(li) + c_matrix(ibf,istate,ispin) * cs_vector_i(ibf)
       endif
     enddo
     proj_charge = proj_charge + occupation(istate,ispin) * SUM(proj_state_i(:))

     write(stdout,'(i3,1x,i5,1x,20(f16.6,4x))') ispin,istate,energy(istate,ispin) * Ha_eV,&
          SUM(proj_state_i(:)),proj_state_i(:)
   enddo
 enddo
 write(stdout,'(1x,a)') '==========================================='
 write(stdout,'(1x,a,f12.6)') 'Total Mulliken charge: ',proj_charge


end subroutine mulliken_pdos


!=========================================================================
subroutine plot_wfn(nstate,basis,c_matrix)
 use m_definitions
 use m_mpi
 use m_inputparam, only: nspin
 use m_atoms
 use m_cart_to_pure
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
!=====
 integer,parameter          :: nr=2000
 real(dp),parameter         :: length=10.0_dp
 integer                    :: gt
 integer                    :: ir,ibf
 integer                    :: istate1,istate2,istate,ispin
 real(dp)                   :: rr(3)
 real(dp),allocatable       :: phi(:,:),phase(:,:)
 real(dp)                   :: u(3),a(3)
 logical                    :: file_exists
 real(dp)                   :: xxmin,xxmax
 real(dp)                   :: basis_function_r(basis%nbf)
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart
 real(dp),allocatable       :: basis_function_r_cart(:)
 integer                    :: wfrfile
!=====

 if( .NOT. is_iomaster ) return

 gt = get_gaussian_type_tag(basis%gaussian_type)

 write(stdout,'(/,1x,a)') 'Plotting some selected wavefunctions'
 inquire(file='manual_plotwfn',exist=file_exists)
 if(file_exists) then
   open(newunit=wfrfile,file='manual_plotwfn',status='old')
   read(wfrfile,*) istate1,istate2
   read(wfrfile,*) u(:)
   read(wfrfile,*) a(:)
   close(wfrfile)
 else
   istate1=1
   istate2=2
   u(:)=0.0_dp
   u(1)=1.0_dp
   a(:)=0.0_dp
 endif
 u(:) = u(:) / SQRT(SUM(u(:)**2))
 allocate(phase(istate1:istate2,nspin),phi(istate1:istate2,nspin))
 write(stdout,'(a,2(2x,i4))')   ' states:   ',istate1,istate2
 write(stdout,'(a,3(2x,f8.3))') ' direction:',u(:)
 write(stdout,'(a,3(2x,f8.3))') ' origin:   ',a(:)

 xxmin = MINVAL( u(1)*x(1,:) + u(2)*x(2,:) + u(3)*x(3,:) ) - length
 xxmax = MAXVAL( u(1)*x(1,:) + u(2)*x(2,:) + u(3)*x(3,:) ) + length

 phase(:,:)=1.0_dp

 do ir=1,nr
   rr(:) = ( xxmin + (ir-1)*(xxmax-xxmin)/REAL(nr-1,dp) ) * u(:) + a(:)

   phi(:,:) = 0.0_dp
   
   !
   ! First precalculate all the needed basis function evaluations at point rr
   !
   ibf_cart = 1
   ibf      = 1
   do while(ibf_cart<=basis%nbf_cart)
     li      = basis%bf(ibf_cart)%am
     ni_cart = number_basis_function_am('CART',li)
     ni      = number_basis_function_am(basis%gaussian_type,li)

     allocate(basis_function_r_cart(ni_cart))

     do i_cart=1,ni_cart
       basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
     enddo
     basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li,gt)%matrix(:,:) )
     deallocate(basis_function_r_cart)

     ibf      = ibf      + ni
     ibf_cart = ibf_cart + ni_cart
   enddo
   !
   ! Precalculation done!
   !

   do ispin=1,nspin
     phi(istate1:istate2,ispin) = MATMUL( basis_function_r(:) , c_matrix(:,istate1:istate2,ispin) )
   enddo

   !
   ! turn the wfns so that they are all positive at a given point
   if(ir==1) then
     do ispin=1,nspin
       do istate=istate1,istate2
         if( phi(istate,ispin) < 0.0_dp ) phase(istate,ispin) = -1.0_dp
       enddo
     enddo
   endif

   write(101,'(50(e16.8,2x))') DOT_PRODUCT(rr(:),u(:)),phi(:,:)*phase(:,:)
   write(102,'(50(e16.8,2x))') DOT_PRODUCT(rr(:),u(:)),phi(:,:)**2

 enddo

 deallocate(phase,phi)

end subroutine plot_wfn


!=========================================================================
subroutine plot_rho(nstate,basis,occupation,c_matrix)
 use m_definitions
 use m_mpi
 use m_atoms
 use m_cart_to_pure
 use m_inputparam, only: nspin
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: occupation(nstate,nspin)
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
!=====
 integer,parameter          :: nr=5000
 real(dp),parameter         :: length=4.0_dp
 integer                    :: gt
 integer                    :: ir,ibf
 integer                    :: istate1,istate2,istate,ispin
 real(dp)                   :: rr(3)
 real(dp),allocatable       :: phi(:,:)
 real(dp)                   :: u(3),a(3)
 logical                    :: file_exists
 real(dp)                   :: xxmin,xxmax
 real(dp)                   :: basis_function_r(basis%nbf)
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart
 real(dp),allocatable       :: basis_function_r_cart(:)
 integer                    :: rhorfile
!=====

 if( .NOT. is_iomaster ) return

 write(stdout,'(/,1x,a)') 'Plotting the density'

 gt = get_gaussian_type_tag(basis%gaussian_type)

 inquire(file='manual_plotrho',exist=file_exists)
 if(file_exists) then
   open(newunit=rhorfile,file='manual_plotrho',status='old')
   read(rhorfile,*) u(:)
   read(rhorfile,*) a(:)
   close(rhorfile)
 else
   u(:)=0.0_dp
   u(1)=1.0_dp
   a(:)=0.0_dp
 endif
 u(:) = u(:) / NORM2(u)
 allocate(phi(nstate,nspin))
 write(stdout,'(a,3(2x,f8.3))') ' direction:',u(:)
 write(stdout,'(a,3(2x,f8.3))') ' origin:   ',a(:)

 xxmin = MINVAL( u(1)*x(1,:) + u(2)*x(2,:) + u(3)*x(3,:) ) - length
 xxmax = MAXVAL( u(1)*x(1,:) + u(2)*x(2,:) + u(3)*x(3,:) ) + length


 do ir=1,nr
   rr(:) = ( xxmin + (ir-1)*(xxmax-xxmin)/REAL(nr-1,dp) ) * u(:) + a(:)

   phi(:,:) = 0.0_dp
   
   !
   ! First precalculate all the needed basis function evaluations at point rr
   !
   ibf_cart = 1
   ibf      = 1
   do while(ibf_cart<=basis%nbf_cart)
     li      = basis%bf(ibf_cart)%am
     ni_cart = number_basis_function_am('CART',li)
     ni      = number_basis_function_am(basis%gaussian_type,li)

     allocate(basis_function_r_cart(ni_cart))

     do i_cart=1,ni_cart
       basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
     enddo
     basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li,gt)%matrix(:,:) )
     deallocate(basis_function_r_cart)

     ibf      = ibf      + ni
     ibf_cart = ibf_cart + ni_cart
   enddo
   !
   ! Precalculation done!
   !

   do ispin=1,nspin
     phi(:,ispin) = MATMUL( basis_function_r(:) , c_matrix(:,:,ispin) )
   enddo

   write(103,'(50(e16.8,2x))') DOT_PRODUCT(rr(:),u(:)),SUM( phi(:,:)**2 * occupation(:,:) )

   write(104,'(50(e16.8,2x))') NORM2(rr(:)),SUM( phi(:,:)**2 * occupation(:,:) ) * 4.0_dp * pi * NORM2(rr(:))**2
!   write(105,'(50(e16.8,2x))') NORM2(rr(:)),SUM( phi(1,:)**2 * occupation(1,:) ) * 4.0_dp * pi * NORM2(rr(:))**2
!   write(106,'(50(e16.8,2x))') NORM2(rr(:)),SUM( phi(2:,:)**2 * occupation(2:,:) ) * 4.0_dp * pi * NORM2(rr(:))**2

 enddo

 deallocate(phi)

end subroutine plot_rho


!=========================================================================
subroutine plot_rho_list(nstate,basis,occupation,c_matrix)
 use m_definitions
 use m_mpi
 use m_atoms
 use m_cart_to_pure
 use m_inputparam, only: nspin
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: occupation(nstate,nspin)
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
!=====
 integer                    :: gt
 integer                    :: ir,ibf
 integer                    :: istate1,istate2,istate,ispin
 real(dp)                   :: rr(3)
 real(dp),allocatable       :: phi(:,:)
 real(dp)                   :: u(3),a(3)
 logical                    :: file_exists
 real(dp)                   :: xxmin,xxmax
 real(dp)                   :: basis_function_r(basis%nbf)
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart
 real(dp),allocatable       :: basis_function_r_cart(:)
 integer                    :: rhorfile
 integer                    :: ix,iy,iz
 integer,parameter          :: nx=75 ! 87
 integer,parameter          :: ny=75 ! 91
 integer,parameter          :: nz=90 ! 65
 real(dp),parameter         :: dx = 0.174913 ! 0.204034
 real(dp)                   :: rr0(3)
 integer                    :: unitfile
!=====

 if( .NOT. is_iomaster ) return

 write(stdout,'(/,1x,a)') 'Plotting the density'

 gt = get_gaussian_type_tag(basis%gaussian_type)

 inquire(file='manual_plotrho',exist=file_exists)
 if(file_exists) then
   open(newunit=rhorfile,file='manual_plotrho',status='old')
   close(rhorfile)
 else
 endif
 allocate(phi(nstate,nspin))

 rr0(1) = -6.512752 ! -8.790885
 rr0(2) = -6.512752 ! -9.143313 
 rr0(3) = -7.775444 ! -6.512752

 open(newunit=unitfile,file='rho.dat',action='WRITE')
 do ix=1,nx
 do iy=1,ny
 do iz=1,nz
   rr(1) = ix-1
   rr(2) = iy-1
   rr(3) = iz-1
   rr(:) = rr0(:) + rr(:) * dx 

   phi(:,:) = 0.0_dp
   
   !
   ! First precalculate all the needed basis function evaluations at point rr
   !
   ibf_cart = 1
   ibf      = 1
   do while(ibf_cart<=basis%nbf_cart)
     li      = basis%bf(ibf_cart)%am
     ni_cart = number_basis_function_am('CART',li)
     ni      = number_basis_function_am(basis%gaussian_type,li)

     allocate(basis_function_r_cart(ni_cart))

     do i_cart=1,ni_cart
       basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
     enddo
     basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li,gt)%matrix(:,:) )
     deallocate(basis_function_r_cart)

     ibf      = ibf      + ni
     ibf_cart = ibf_cart + ni_cart
   enddo
   !
   ! Precalculation done!
   !

   do ispin=1,nspin
     phi(:,ispin) = MATMUL( basis_function_r(:) , c_matrix(:,:,ispin) )
   enddo

   write(unitfile,'(1x,e16.8)') SUM( phi(3:,:)**2 * occupation(3:,:) )

 enddo
 enddo
 enddo
 close(unitfile)

 deallocate(phi)

end subroutine plot_rho_list


!=========================================================================
subroutine plot_cube_wfn(nstate,basis,occupation,c_matrix)
 use m_definitions
 use m_mpi
 use m_inputparam, only: nspin,spin_fact
 use m_cart_to_pure
 use m_atoms
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: occupation(nstate,nspin)
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
!=====
 integer                    :: gt
 integer                    :: nx
 integer                    :: ny
 integer                    :: nz
 real(dp),parameter         :: length=4.0_dp
 integer                    :: ibf
 integer                    :: istate1,istate2,istate,ispin
 real(dp)                   :: rr(3)
 real(dp),allocatable       :: phi(:,:)
 real(dp)                   :: u(3),a(3)
 logical                    :: file_exists
 real(dp)                   :: xxmin,xxmax,ymin,ymax,zmin,zmax
 real(dp)                   :: basis_function_r(basis%nbf)
 integer                    :: ix,iy,iz,iatom
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart
 real(dp),allocatable       :: basis_function_r_cart(:)
 integer,allocatable        :: ocubefile(:,:)
 integer                    :: ocuberho(nspin)
 character(len=200)         :: file_name
 integer                    :: icubefile
!=====

 if( .NOT. is_iomaster ) return

 write(stdout,'(/,1x,a)') 'Plotting some selected wavefunctions in a cube file'

 gt = get_gaussian_type_tag(basis%gaussian_type)

 inquire(file='manual_cubewfn',exist=file_exists)
 if(file_exists) then
   open(newunit=icubefile,file='manual_cubewfn',status='old')
   read(icubefile,*) istate1,istate2
   read(icubefile,*) nx,ny,nz
   close(icubefile)
 else
   istate1=1
   istate2=2
   nx=40
   ny=40
   nz=40
 endif
 allocate(phi(istate1:istate2,nspin))
 write(stdout,'(a,2(2x,i4))')   ' states:   ',istate1,istate2

 xxmin = MINVAL( x(1,:) ) - length
 xxmax = MAXVAL( x(1,:) ) + length
 ymin = MINVAL( x(2,:) ) - length
 ymax = MAXVAL( x(2,:) ) + length
 zmin = MINVAL( x(3,:) ) - length
 zmax = MAXVAL( x(3,:) ) + length

 allocate(ocubefile(istate1:istate2,nspin))

 do istate=istate1,istate2
   do ispin=1,nspin
     write(file_name,'(a,i3.3,a,i1,a)') 'wfn_',istate,'_',ispin,'.cube'
     open(newunit=ocubefile(istate,ispin),file=file_name)
     write(ocubefile(istate,ispin),'(a)') 'cube file generated from MOLGW'
     write(ocubefile(istate,ispin),'(a,i4)') 'wavefunction ',istate1
     write(ocubefile(istate,ispin),'(i6,3(f12.6,2x))') natom,xxmin,ymin,zmin
     write(ocubefile(istate,ispin),'(i6,3(f12.6,2x))') nx,(xxmax-xxmin)/REAL(nx,dp),0.,0.
     write(ocubefile(istate,ispin),'(i6,3(f12.6,2x))') ny,0.,(ymax-ymin)/REAL(ny,dp),0.
     write(ocubefile(istate,ispin),'(i6,3(f12.6,2x))') nz,0.,0.,(zmax-zmin)/REAL(nz,dp)
     do iatom=1,natom
       write(ocubefile(istate,ispin),'(i6,4(2x,f12.6))') basis_element(iatom),0.0,x(:,iatom)
     enddo
   enddo
 enddo

 !
 ! check whether istate1:istate2 spans all the occupied states
 if( istate1==1 .AND. ALL( occupation(istate2+1,:) < completely_empty ) ) then
   do ispin=1,nspin
     write(file_name,'(a,i1,a)') 'rho_',ispin,'.cube'
     open(newunit=ocuberho(ispin),file=file_name)
     write(ocuberho(ispin),'(a)') 'cube file generated from MOLGW'
     write(ocuberho(ispin),'(a,i4)') 'density for spin ',ispin
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') natom,xxmin,ymin,zmin
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') nx,(xxmax-xxmin)/REAL(nx,dp),0.,0.
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') ny,0.,(ymax-ymin)/REAL(ny,dp),0.
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') nz,0.,0.,(zmax-zmin)/REAL(nz,dp)
     do iatom=1,natom
       write(ocuberho(ispin),'(i6,4(2x,f12.6))') NINT(zatom(iatom)),0.0,x(:,iatom)
     enddo
   enddo
 endif

 do ix=1,nx
   rr(1) = ( xxmin + (ix-1)*(xxmax-xxmin)/REAL(nx,dp) ) 
   do iy=1,ny
     rr(2) = ( ymin + (iy-1)*(ymax-ymin)/REAL(ny,dp) ) 
     do iz=1,nz
       rr(3) = ( zmin + (iz-1)*(zmax-zmin)/REAL(nz,dp) ) 


       phi(:,:) = 0.0_dp
       
       !
       ! First precalculate all the needed basis function evaluations at point rr
       !
       ibf_cart = 1
       ibf      = 1
       do while(ibf_cart<=basis%nbf_cart)
         li      = basis%bf(ibf_cart)%am
         ni_cart = number_basis_function_am('CART',li)
         ni      = number_basis_function_am(basis%gaussian_type,li)
    
         allocate(basis_function_r_cart(ni_cart))
    
         do i_cart=1,ni_cart
           basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
         enddo
         basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li,gt)%matrix(:,:) )
         deallocate(basis_function_r_cart)
    
         ibf      = ibf      + ni
         ibf_cart = ibf_cart + ni_cart
       enddo
       !
       ! Precalculation done!
       !

       do ispin=1,nspin
         phi(istate1:istate2,ispin) = MATMUL( basis_function_r(:) , c_matrix(:,istate1:istate2,ispin) )
       enddo

       !
       ! check whether istate1:istate2 spans all the occupied states
       if( istate1==1 .AND. ALL( occupation(istate2+1,:) < completely_empty ) ) then
         do ispin=1,nspin
           write(ocuberho(ispin),'(50(e16.8,2x))') SUM( phi(:,ispin)**2 * occupation(istate1:istate2,ispin) ) * spin_fact
         enddo
       endif


       do istate=istate1,istate2
         do ispin=1,nspin
           write(ocubefile(istate,ispin),'(50(e16.8,2x))') phi(istate,ispin)
         enddo
       enddo

     enddo
   enddo
 enddo

 deallocate(phi)

 do istate=istate1,istate2
   do ispin=1,nspin
     close(ocubefile(istate,ispin))
   enddo
 enddo

end subroutine plot_cube_wfn


!=========================================================================
subroutine plot_cube_wfn_cmplx(nstate,basis,occupation,c_matrix_cmplx,num)
 use m_definitions
 use m_mpi
 use m_inputparam, only: nspin,spin_fact
 use m_atoms
 use m_basis_set
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: occupation(nstate,nspin)
 complex(dp),intent(in)     :: c_matrix_cmplx(basis%nbf,nstate,nspin)
 integer                    :: num
!=====
 integer                    :: nx
 integer                    :: ny
 integer                    :: nz
 integer                    :: nocc(2)
 real(dp),parameter         :: length=4.0_dp
 integer                    :: ibf
 integer                    :: istate1,istate2,istate,ispin
 real(dp)                   :: rr(3)
 complex(dp),allocatable    :: phi_cmplx(:,:)
 real(dp)                   :: u(3),a(3)
 logical                    :: file_exists
 real(dp)                   :: xxmin,xxmax,ymin,ymax,zmin,zmax
 real(dp)                   :: basis_function_r(basis%nbf)
 integer                    :: ix,iy,iz,iatom
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart
 real(dp),allocatable       :: basis_function_r_cart(:)
 integer,allocatable        :: ocubefile(:,:)
 integer                    :: ocuberho(nspin)
 character(len=200)         :: file_name
 integer                    :: icubefile
!=====

 if( .NOT. is_iomaster ) return

 write(stdout,'(/,1x,a)') 'Plotting some selected wavefunctions in a cube file'
 ! Find highest occupied state
 nocc = 0
 do ispin=1,nspin
   do istate=1,nstate
     if( occupation(istate,ispin) < completely_empty)  cycle
     nocc(ispin) = istate
   enddo 
   if( .NOT. (ALL( occupation(nocc(ispin)+1,:) < completely_empty )) ) then
     call die('Not all occupied states selected in the plot_cube_wfn_cmplx')
   endif 
 enddo

 inquire(file='manual_cubewfn',exist=file_exists)
 if(file_exists) then
   open(newunit=icubefile,file='manual_cubewfn',status='old')
   read(icubefile,*) istate1,istate2
   read(icubefile,*) nx,ny,nz
   close(icubefile)
 else
   istate1=1
   istate2=nocc(1)
   nx=40
   ny=40
   nz=40
 endif
 allocate(phi_cmplx(istate1:istate2,nspin))
 write(stdout,'(a,2(2x,i4))')   ' states:   ',istate1,istate2




 xxmin = MINVAL( x(1,:) ) - length
 xxmax = MAXVAL( x(1,:) ) + length
 ymin = MINVAL( x(2,:) ) - length
 ymax = MAXVAL( x(2,:) ) + length
 zmin = MINVAL( x(3,:) ) - length
 zmax = MAXVAL( x(3,:) ) + length



 
   do ispin=1,nspin

!     write(file_name,'(a,i1,a,i3.3,a)') 'rho_',ispin,'_',num,'.cube'
     write(file_name,'(i3.3,a)') num,'.cube'
     open(newunit=ocuberho(ispin),file=file_name)                
     write(ocuberho(ispin),'(a)') 'cube file generated from MOLG W'
     write(ocuberho(ispin),'(a,i4)') 'density for spin ',ispin   
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') natom,xxmin,ymin, zmin
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') nx,(xxmax-xxmin)/ REAL(nx,dp),0.,0.
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') ny,0.,(ymax-ymin)/REAL(ny,dp),0.
     write(ocuberho(ispin),'(i6,3(f12.6,2x))') nz,0.,0.,(zmax-zmin)/REAL(nz,dp)
     do iatom=1,natom
       write(ocuberho(ispin),'(i6,4(2x,f12.6))') NINT(zatom(iatom)),0.0,x(:,iatom)
     enddo
   enddo

 do ix=1,nx
   rr(1) = ( xxmin + (ix-1)*(xxmax-xxmin)/REAL(nx,dp) ) 
   do iy=1,ny
     rr(2) = ( ymin + (iy-1)*(ymax-ymin)/REAL(ny,dp) ) 
     do iz=1,nz
       rr(3) = ( zmin + (iz-1)*(zmax-zmin)/REAL(nz,dp) ) 


       phi_cmplx(:,:) = ( 0.0_dp, 0.0_dp )
       
       !
       ! First precalculate all the needed basis function evaluations at point rr
       !
       ibf_cart = 1
       ibf      = 1
       do while(ibf_cart<=basis%nbf_cart)
         li      = basis%bf(ibf_cart)%am
         ni_cart = number_basis_function_am('CART',li)
         ni      = number_basis_function_am(basis%gaussian_type,li)
    
         allocate(basis_function_r_cart(ni_cart))
    
         do i_cart=1,ni_cart
           basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
         enddo
         basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li)%matrix(:,:) )
         deallocate(basis_function_r_cart)
    
         ibf      = ibf      + ni
         ibf_cart = ibf_cart + ni_cart
       enddo
       !
       ! Precalculation done!
       !

       do ispin=1,nspin
         istate2=nocc(ispin)
         phi_cmplx(istate1:istate2,ispin) = MATMUL( basis_function_r(:) , c_matrix_cmplx(:,istate1:istate2,ispin) )
         write(ocuberho(ispin),'(50(e16.8,2x))') SUM( abs(phi_cmplx(:,ispin))**2 * occupation(istate1:istate2,ispin) ) * spin_fact
       enddo

     enddo
   enddo
 enddo

 do ispin=1,nspin
   close(ocuberho(ispin))
 end do

 deallocate(phi_cmplx)

end subroutine plot_cube_wfn_cmplx



!=========================================================================
subroutine write_energy_qp(nstate,energy_qp)
 use m_definitions
 use m_mpi
 use m_inputparam,only: nspin
 implicit none

 integer,intent(in)  :: nstate
 real(dp),intent(in) :: energy_qp(nstate,nspin)
!=====
 integer           :: energy_qpfile
 integer           :: istate
!=====

 !
 ! Only the proc iomaster writes down the ENERGY_QP file
 if( .NOT. is_iomaster) return

 write(stdout,'(/,a)') ' Writing ENERGY_QP file'


 open(newunit=energy_qpfile,file='ENERGY_QP',form='formatted')

 write(energy_qpfile,*) nspin
 write(energy_qpfile,*) nstate
 do istate=1,nstate
   write(energy_qpfile,*) istate,energy_qp(istate,:)
 enddo

 close(energy_qpfile)


end subroutine write_energy_qp


!=========================================================================
subroutine read_energy_qp(nstate,energy_qp,reading_status)
 use m_definitions
 use m_mpi
 use m_warning,only: issue_warning
 use m_inputparam,only: nspin
 implicit none

 integer,intent(in)   :: nstate
 integer,intent(out)  :: reading_status
 real(dp),intent(out) :: energy_qp(nstate,nspin)
!=====
 integer           :: energy_qpfile
 integer           :: istate,jstate
 integer           :: nspin_read,nstate_read
 logical           :: file_exists_capitalized,file_exists
!=====

 write(stdout,'(/,a)') ' Reading ENERGY_QP file'

 inquire(file='ENERGY_QP',exist=file_exists_capitalized)
 inquire(file='energy_qp',exist=file_exists)

 if(file_exists_capitalized) then
   open(newunit=energy_qpfile,file='ENERGY_QP',form='formatted',status='old')
 else if(file_exists) then
   open(newunit=energy_qpfile,file='energy_qp',form='formatted',status='old')
 endif

 if( file_exists_capitalized .OR. file_exists ) then
   read(energy_qpfile,*) nspin_read
   read(energy_qpfile,*) nstate_read
   if( nstate_read /= nstate .OR. nspin_read /= nspin ) then
     call issue_warning('ENERGY_QP file does not have the correct dimensions')
     reading_status=2
   else
     do istate=1,nstate
       read(energy_qpfile,*) jstate,energy_qp(istate,:)
       ! Scissor operator
       if( jstate == -1 ) then
         reading_status=-1
         close(energy_qpfile)
         return
       endif
     enddo
     reading_status=0
   endif
   close(energy_qpfile)
 else
   reading_status=1
   call issue_warning('files ENERGY_QP and energy_qp do not exist')
 endif


end subroutine read_energy_qp


!=========================================================================
function evaluate_wfn_r(nspin,nstate,basis,c_matrix,istate,ispin,rr)
 use m_definitions
 use m_mpi
 use m_atoms
 use m_cart_to_pure
 use m_basis_set
 implicit none
 integer,intent(in)         :: nspin
 type(basis_set),intent(in) :: basis
 integer,intent(in)         :: nstate
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
 integer,intent(in)         :: istate,ispin
 real(dp),intent(in)        :: rr(3)
 real(dp)                   :: evaluate_wfn_r
!=====
 integer                    :: gt
 integer                    :: ibf_cart,ni_cart,ni,li,i_cart,ibf
 real(dp),allocatable       :: basis_function_r_cart(:)
 real(dp)                   :: basis_function_r(basis%nbf)
!=====

 gt = get_gaussian_type_tag(basis%gaussian_type)

 !
 ! First precalculate all the needed basis function evaluations at point rr
 !
 ibf_cart = 1
 ibf      = 1
 do while(ibf_cart<=basis%nbf_cart)
   li      = basis%bf(ibf_cart)%am
   ni_cart = number_basis_function_am('CART',li)
   ni      = number_basis_function_am(basis%gaussian_type,li)

   allocate(basis_function_r_cart(ni_cart))

   do i_cart=1,ni_cart
     basis_function_r_cart(i_cart) = eval_basis_function(basis%bf(ibf_cart+i_cart-1),rr)
   enddo
   basis_function_r(ibf:ibf+ni-1) = MATMUL(  basis_function_r_cart(:) , cart_to_pure(li,gt)%matrix(:,:) )
   deallocate(basis_function_r_cart)

   ibf      = ibf      + ni
   ibf_cart = ibf_cart + ni_cart
 enddo
 !
 ! Precalculation done!
 !

 evaluate_wfn_r = DOT_PRODUCT( basis_function_r(:) , c_matrix(:,istate,ispin) )


end function evaluate_wfn_r


!=========================================================================
function wfn_parity(nstate,basis,c_matrix,istate,ispin)
 use m_definitions
 use m_mpi
 use m_atoms
 use m_basis_set
 use m_inputparam
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
 integer,intent(in)         :: istate,ispin
 integer                    :: wfn_parity
!=====
 real(dp) :: phi_tmp1,phi_tmp2,xtmp(3)
 real(dp),external :: evaluate_wfn_r
!=====

 xtmp(1) = xcenter(1) +  2.0_dp
 xtmp(2) = xcenter(2) +  1.0_dp
 xtmp(3) = xcenter(3) +  3.0_dp
 phi_tmp1 = evaluate_wfn_r(nspin,nstate,basis,c_matrix,istate,ispin,xtmp)
 xtmp(1) = xcenter(1) -  2.0_dp
 xtmp(2) = xcenter(2) -  1.0_dp
 xtmp(3) = xcenter(3) -  3.0_dp
 phi_tmp2 = evaluate_wfn_r(nspin,nstate,basis,c_matrix,istate,ispin,xtmp)

 if( ABS(phi_tmp1 - phi_tmp2)/ABS(phi_tmp1) < 1.0e-6_dp ) then
   wfn_parity = 1
 else
   wfn_parity = -1
 endif
 

end function wfn_parity


!=========================================================================
function wfn_reflection(nstate,basis,c_matrix,istate,ispin)
 use m_definitions
 use m_mpi
 use m_atoms
 use m_basis_set
 use m_inputparam
 implicit none
 integer,intent(in)         :: nstate
 type(basis_set),intent(in) :: basis
 real(dp),intent(in)        :: c_matrix(basis%nbf,nstate,nspin)
 integer,intent(in)         :: istate,ispin
 integer                    :: wfn_reflection
!=====
 real(dp) :: phi_tmp1,phi_tmp2,xtmp1(3),xtmp2(3)
 real(dp) :: proj
 real(dp),external :: evaluate_wfn_r
!=====

 xtmp1(1) = x(1,1) +  2.0_dp
 xtmp1(2) = x(2,1) +  1.0_dp
 xtmp1(3) = x(3,1) +  3.0_dp
 phi_tmp1 = evaluate_wfn_r(nspin,nstate,basis,c_matrix,istate,ispin,xtmp1)

 proj = DOT_PRODUCT( xtmp1 , xnormal )
 xtmp2(:) = xtmp1(:) -  2.0_dp * proj * xnormal(:)
 phi_tmp2 = evaluate_wfn_r(nspin,nstate,basis,c_matrix,istate,ispin,xtmp2)

 if( ABS(phi_tmp1 - phi_tmp2)/ABS(phi_tmp1) < 1.0e-6_dp ) then
   wfn_reflection = 1
 else if( ABS(phi_tmp1 + phi_tmp2)/ABS(phi_tmp1) < 1.0e-6_dp ) then
   wfn_reflection = -1
 else 
   wfn_reflection = 0
 endif


end function wfn_reflection


!=========================================================================
