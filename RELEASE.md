-----------------------------------------
#    MOLGW: Release Notes
-----------------------------------------


-----------------------------------------
## What's new in version 2.F
### Overview
- MOLGW is now compatible with LIBXC 5
- MOLGW automatically detects the LIBINT configuration. Easier compilation
- Possibility to add point charges in the structure

### Contributors
- Fabien Bruneval (CEA SRMP, France)

### Changes affecting the usage
- Fractional point charges (without basis functions) can be specified in the structure using the syntax:
 0.100   0.000  0.000  0.000   none  none   #   q   x y z  basis  auxiliary_basis

### Changes affecting the compilation
- MOLGW can be linked against LIBXC 5
- MOLGW detects LIBINT configuration to know wheter the one-body integrals and the gradients are available. Preprocessor instructions such as `-DHAVE_LIBNIT_ONEDOBY` are not needed anymore.


-----------------------------------------
## What's new in version 2.E
### Overview
- MOLGW proposes automatically an extrapolated GW energy to the  Complete Basis Set limit when using Dunning basis sets
- GW with analytic continuation is now robust for the HOMO-LUMO gap region. Tested for C60 in aug-cc-pV5Z (>7500 basis functions)
- small bug fixes, speed-ups, memory reductions

### Contributors
- Fabien Bruneval (CEA SRMP, France)
- Xixi Qi (CEA SRMP, France)
- Mauricio Rodriguez-Mayorga (CEA SRMP, France)

### Changes affecting the usage
- Automatic suggestion of an extrapolation to the Complete Basis Set limit for GW energies
- GW analytic continuation technique is fully functional. Use postscf='G0W0_pade'. It is much faster than the analytic formula but it is mostly reliable close to the HOMO-LUMO gap.
- Reduced memory consumption in the Pulay history (SCALAPACK distribution of the large arrays)
- Improved OPENMP

### Changes affecting the compilation
- Assuming now that all Fortran compilers have Fortran 2008 capabilities. Preprocessor key FORTRAN2008 has been removed.

### Changes affecting the developers
- Introduce high-level mpi tools for instance, world%sum() for reduction, world%nproc, world%rank for information


-----------------------------------------
## What's new in version 2.D
### Overview
- Compatibility with gcc/gfortran 10
- Basis files location can be set from an environment variable MOLGW_BASIS_PATH
- Printing of standard WFN files

### Contributors
- Fabien Bruneval (CEA SRMP, France)
- Mauricio Rodriguez-Mayorga (CEA SRMP, France)

### Changes affecting the usage
- Keyword `print_wfn_file` triggers the output of a standard WFN file that can be read with external visualization softwares.
- Environment variable `MOLGW_BASIS_PATH` sets the path to the basis files. It is still be overridden by the input keyword `basis_path`.
- New default value for `postscf_diago_flavor=' '`. Though faster, the former default value was not stable enough for large systems.

### Changes affecting the compilation
- GCC 10 is very picky on the routine calls without an interfaces. Many existing calls to BLAS/LAPACK/SCALAPACK had to be fixed.
- Makefile, my_machine.arch use more standard `FCFLAGS` and `CXXFLAGS` variables instead of `FCOPTS` and `CXXOPTS`
- Fortran long lines have been chopped into pieces so to comply with the 132 character limit of Fortran.
Compiler options such as `-ffree-line-length-none` are not needed any more.

### Changes affecting the developers
- Please respect the 132-character limit of Fortran.


-----------------------------------------
## What's new in version 2.C
### Overview
- Real-time TDDFT is made available
- speed-up in the Hartree, Exchange and AO to MO transform
- calculation of the generalized oscillator strengths (q-dependent) and linear-response stopping power
- use of LIBXC through the C interface
- compatibility with the latest LIBINT versions restored
- creation of a YAML output file that gathers many information that can be easily post-processed via python
- bug fixes

### Contributors
- Fabien Bruneval (CEA SRMP, France)
- Ivan Maliyov (CEA SRMP, France)
- Young-Moo Byun (U. Illinois@Chicago, USA)

### Changes affecting the usage
- Post-processing is not performed if the SCF cycles are not converged within `tolscf` (save user CPU time when a job went wrong)
- Keywords `scalapack_nprow` and `scalapack_npcol` have been eliminated
- Keyword `stopping` triggers the linear-response stopping power calculation
- Value `postscf='real_time'` triggers real-time TDDFT (RT-TDDFT)
- New default value for `postscf_diago_flavor='D'`
- OPENMP parallelisation effort is pursued
- Bug fix of the output of the COHSEX energies (bug discovered by Arjan Berger)

### Changes affecting the compilation
- LIBXC is now linked through the C interface. Therefore, LIBXC compilation does not need to be consistent with MOLGW compilation.
The latest version of LIBXC can be used. Preprocessing flag `-DLIBXC4` is no longer needed.
- Preprocessing option `-DHAVE_MKL` allows for the use of MKL extensions and in particular of `DGEMMT`.
- Use of modern Fortran2008 syntax, such as c%re to obtain the real part of a complex number. Code imcompatible with older compilers (gfortran > 9.0 necessary)

### Changes affecting the developers
- The list of all the input variables is now stored in a YAML file ~molgw/src/input_variables.yaml that is processed with the python script ~molgw/utils/input_variables.py


-----------------------------------------
## What's new in version 2.B
### Overview
- automatic generation of an auxiliary basis following the "Auto" and "PAuto" recipes of Gaussian
- output the Galitskii-Migdal correlation energy = 1/2 Tr[ Sigmac * G ]
- non HF starting points for perturbation theory density matrices
- speed-up in RT-TDDFT
- bug fixes

### Contributors
- Fabien Bruneval (CEA SRMP, France)
- Young-Moo Byun (U. Illinois@Chicago, USA)
- Ivan Maliyov (CEA SRMP, France)

### Changes affecting the usage
- Keyword `auxil_basis='auto'` or `auxil_basis='pauto'` triggers automatic generation of an auxiliary basis


-----------------------------------------
## What's new in version 2.A
### Overview
- GW approximation to the density matrix (only for spin-restricted calculations)
- Third-order perturbation theory (PT3) self-energy (only for spin-restricted calculations)
- OPENMP parallelization
- better graphical solution to the QP equation
- complex wavefunctions and Hamiltonian can be calculated (for real-time TDDFT)
- possibility to use different diagonalization routines
- reduced memory foot print in the 3-center integral set up
- possibility to read formatted checkpoint files from Gaussian (.fchk) and use the read density matrix
- speed-up
- bug fixes

### Contributors
- Fabien Bruneval (CEA SRMP, France)
- Young-Moo Byun (U. Illinois@Chicago, USA)
- Ivan Maliyov (CEA SRMP, France)

### Changes affecting the results
- The graphical solution of the QP equation now selects the fixed point energy that maximises the spectral weight of the peak.
This may change some QP energies away from the HOMO-LUMO gap. As the consequence, the BSE excitation energies are slightly affected.

### Changes affecting the usage
- Keyword `pt_density_matrix` triggers the GW or PT2 density matrix calculation
- Keyword `postscf='PT3'` triggers the PT3 self-energy calculation [see Cederbaum's papers](https://doi.org/10.1016/0167-7977%2884%2990002-9)
- Keyword `read_fchk` allows the user to read a Gaussian formatted file (.fchk)
and resuse the density matrix `read_fchk='SCF'`, `read_fchk='MP2'`, and `read_fchk='CC'`. Only works for Cartesian Gaussian and make sure to use the exact same basis set in the two codes. Gaussian uses modification of the Dunning basis set for instance. A few are available in MOLGW with `basis='cc-pVQZ_gaussian'`.
- OPENMP parallelization is now available for the no-RI part with a special care about the reduction of the NUMA effect.
- Hybrid parallelization (OPENMP/MPI) is now available for most the RI code. The coding heavily relies on the availability of threaded BLAS routines.
When using Intel MKL, please export the corresponding environment variables:
`export OMP_NUM_THREADS=4` and `export MKL_NUM_THREADS=4`.
MOLGW has been shown to run efficiently on Intel KNL architecture
- Memory foot print can be reduced when the memory peak was in the calculation of the 3-center integrals.
Use keyword `eri3_nbatch`. Setting `eri3_nbatch` to a value larger than 1 will decrease the memory consumption in the 3-center integrals calculation and hopefully will not hit too much on the performance.
- Possibility to change the diagonalization subroutines with input variables `scf_diago_flavor` and `postscf_diago_flavor`.
Based on our experience, flavor 'R' pointing to (P)DSYEVR is faster but can induce SCF cycle issues. Flavor ' ' pointing to (P)DYSEV is the safest possibility.

### Changes affecting the compilation
- Fortran compiler needs to be capable of using the polymorphic `class(*)` declarations (Fortran2003).
- `-DDEBUG` produces an outfile for each MPI thread.


-----------------------------------------
## What's new in version 1.H
### Overview
Bug fixes

### Changes affecting the compilation
- MOLGW is now compatible with LIBINT versions 2.4.x
- Possibility to compile MOLGW with LIBINT having the one-body integrals, but not the gradients.
Use the preprocessor flags -DHAVE_LIBINT_ONEBODY and/or -DHAVE_LIBINT_GRADIENTS


-----------------------------------------
## What's new in version 1.G
### Overview
Bug fixes, cleaning, and speed-up.

### Changes affecting the compilation
- Still not possible to link with the versions 4 of LIBXC, due to missing functions on their side

### Changes affecting the usage
- The default value for **read_restart** is now set to 'no'
- Speed-up in the semi-local DFT Vxc calculations thanks to the use of batches


-----------------------------------------
## What's new in version 1.F
### Overview
A few bugs specific to the recent versions of the Intel compilers have been fixed.


-----------------------------------------
## What's new in version 1.E
### Overview
Bug fix with respect to previous version for high angular momenta (L>5)
Considerable speed-up in the diagonalization of the RPA matrix thanks to the use of PDSYEVR instead of PDSYEV


-----------------------------------------
## What's new in version 1.D
### Overview
Simple bug fix with respect to previous version


-----------------------------------------
## What's new in version 1.C
### Overview
This release makes better use of the latest version of LIBINT ( >= v2.2.0).
Together with some internal refactoring of the code and small bug fixes.

### Changes affecting the compilation
- Linking with a recent version of LIBINT (>=v2.2.0) is compulsory
- Compilation flag **-DHAVE_LIBINT_ONEBODY** activates the use of LIBINT one-body integrals and integral gradients
- Use of libtool is no longer necessary

### Changes affecting the usage
- Input variable **no_4center** has been removed.
From now on, the calculations use or do not use resolution-of-identity from the beginning to end.
