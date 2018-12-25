submodule (io) makedirs


contains


module procedure create_outdir
!! CREATES OUTPUT DIRECTORY, MOVES CONFIG FILES THERE AND GENERATES A GRID OUTPUT FILE

integer :: ierr

!> MAKE A COPY OF THE INPUT DATA IN THE OUTPUT DIRECTORY (MAYBE SHOULD COPY SOURCE CODE TOO???)
call execute_command_line('mkdir -pv '//outdir//'/inputs', exitstat=ierr)
if (ierr /= 0) error stop 'error creating output directory' 

call execute_command_line('cp -r '//infile//' '//outdir//'/inputs/', exitstat=ierr)
if (ierr /= 0) error stop 'error copying input parameters to output directory' 
call execute_command_line('cp -r '//indatsize//' '//outdir//'/inputs/', exitstat=ierr)
if (ierr /= 0) error stop 'error copying input parameters to output directory' 
call execute_command_line('cp -r '//indatgrid//' '//outdir//'/inputs/', exitstat=ierr)
if (ierr /= 0) error stop 'error copying input parameters to output directory' 
call execute_command_line('cp -r '//indatfile//' '//outdir//'/inputs/', exitstat=ierr)
if (ierr /= 0) error stop 'error copying input parameters to output directory' 

!> MAKE COPIES OF THE INPUT DATA, AS APPROPRIATE
if (flagdneu/=0) then
  call execute_command_line('mkdir -pv '//outdir//'/inputs/neutral_inputs')
  call execute_command_line('cp -r '//sourcedir//'/* '//outdir//'/inputs/neutral_inputs/', exitstat=ierr)
end if
if (ierr /= 0) error stop 'error copying neutral input parameters to output directory' 

if (flagprecfile/=0) then
  call execute_command_line('mkdir -pv '//outdir//'/inputs/prec_inputs')
  call execute_command_line('cp -r '//precdir//'/* '//outdir//'/inputs/prec_inputs/', exitstat=ierr)
end if
if (ierr /= 0) error stop 'error copying input precipitation parameters to output directory' 

if (flagE0file/=0) then
  call execute_command_line('mkdir -pv '//outdir//'/inputs/Efield_inputs')
  call execute_command_line('cp -r '//E0dir//'/* '//outdir//'/inputs/Efield_inputs/', exitstat=ierr)
end if
if (ierr /= 0) error stop 'error copying input energy parameters to output directory' 

!> NOW STORE THE VERSIONS/COMMIT IDENTIFIER IN A FILE IN THE OUTPUT DIRECTORY
! this can break on POSIX due to copying files in endless loop, commended out - MH
!call execute_command_line('mkdir -pv '//outdir//'/inputs/source/', exitstat=ierr)
!if (ierr /= 0) error stop 'error creating input source parameter output directory'
!call execute_command_line('cp -r ./* '//outdir//'/inputs/source/', exitstat=ierr)
!if (ierr /= 0) error stop 'error creating input source parameter output directory' 

call gitlog(outdir//'/gitrev.log')

call compiler_log(outdir//'/compiler.log')

end procedure create_outdir


module procedure create_outdir_mag
!! CREATES OUTPUT DIRECTORY FOR MAGNETIC FIELD CALCULATIONS

!> NOTE: OUTDIR IS BASE DIRECTORY FOR SIMULATION OUTPUT
call execute_command_line('mkdir -pv '//outdir//'/magfields/')
call execute_command_line('mkdir -pv '//outdir//'/magfields/input/')
call execute_command_line('cp -v '//fieldpointfile//' '//outdir//'/magfields/input/magfieldpoints.dat')

end procedure create_outdir_mag


module procedure create_outdir_aur
!! CREATES OUTPUT DIRECTORY FOR MAGNETIC FIELD CALCULATIONS

!NOTE HERE THAT WE INTERPRET OUTDIR AS THE BASE DIRECTORY CONTAINING SIMULATION OUTPUT
call execute_command_line('mkdir -pv '//outdir//'/aurmaps/')

end procedure create_outdir_aur


end submodule makedirs
