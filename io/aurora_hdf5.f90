submodule(io:io_aurora) io_aurora_hdf5

use timeutils, only : date_filename
use hdf5_interface, only: hdf5_file

contains

module procedure output_aur_root
! subroutine output_aur_root(outdir,flagglow,ymd,UTsec,iver)
!! COLLECT COMPLETE DATA FROM WORKERS AND PROCESS FOR OUTPUT.
!! NO GHOST CELLS (I HOPE)

type(hdf5_file) :: h5f

real(wp), dimension(1:lwave,1:lx2,1:lx3) :: ivertmp
real(wp), dimension(1:lwave,1:lx2all,1:lx3all) :: iverall

real(wp), dimension(1:lx2,1:lx3) :: emistmp                !< single emission subgrid
real(wp), dimension(1:lx2all,1:lx3all) :: emisall          !< single emission total grid
real(wp), dimension(1:lx2all,1:lx3all,1:lwave) :: iverout  !< output array in the order scripts expect
integer :: iwave

character(:), allocatable :: outdir_composite, filenamefull, fstatus
integer :: u
logical :: exists

!! gather output from workers
do iwave=1,lwave
  emistmp=iver(:,:,iwave)
  call gather_recv(emistmp,tagAur,emisall)
  iverout(:,:,iwave)=emisall
end do

!! create an output file
outdir_composite=outdir//'/aurmaps/'
filenamefull=date_filename(outdir_composite,ymd,UTsec) // '.h5'
!inquire(file=filenamefull, exist=exists)
!if (exists) then
!  fstatus = 'unknown'
!else
  print *, 'Output file name (auroral maps):  ',filenamefull
  fstatus = 'new'
!endif
call h5f%initialize(filenamefull, status=fstatus,action='rw',comp_lvl=1)

!! write data to file
if(flagswap/=1) then
  call h5f%add('/aurora/iverout', iverout)
  call h5f%add('/aurora/zxden', zxden)
else
  call h5f%add('/aurora/iverout', reshape(iverout,[lx3all,lx2all,lwave],order=[2,1,3]))
  call h5f%add('/aurora/zxden', reshape(zxden,[lx3all,lx2all,12,lx1], order=[2,1,3,4]))
end if

call h5f%finalize()

end procedure output_aur_root

end submodule io_aurora_hdf5