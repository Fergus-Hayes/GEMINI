submodule (io) readhdf5

use hdf5_interface, only: hdf5_file

implicit none

contains


module procedure input_root_mpi

!------------------------------------------------------------
!-------READ INPUT FROM FILE AND DISTRIBUTE TO WORKERS.  
!-------STATE VARS ARE EXPECTED INCLUDE GHOST CELLS.  NOTE ALSO
!-------THAT RECORD-BASED INPUT IS USED SO NO FILES > 2GB DUE
!-------TO GFORTRAN BUG WHICH DISALLOWS 8 BYTE INTEGER RECORD
!-------LENGTHS.
!------------------------------------------------------------


integer :: lx1,lx2,lx3,lx3all,isp

real(wp), dimension(-1:size(x1,1)-2,-1:size(x2,1)-2,-1:size(x3all,1)-2,1:lsp) :: nsall, vs1all, Tsall
real(wp), dimension(:,:,:,:), allocatable :: statetmp
integer :: lx1in,lx2in,lx3in,u

real(wp) :: tstart,tfin

character(:), allocatable :: h5fn
type(hdf5_file) :: h5f

h5fn = indatfile(1:len(indatfile)-4)//'.h5'

!> so that random values (including NaN) don't show up in Ghost cells
nsall = 0._wp
vs1all= 0._wp
Tsall = 0._wp

!> SYSTEM SIZES
lx1=size(ns,1)-4
lx2=size(ns,2)-4
lx3=size(ns,3)-4
lx3all=size(nsall,3)-4

        
!READ IN FROM FILE, AS OF CURVILINEAR BRANCH THIS IS NOW THE ONLY INPUT
!OPTION
open(newunit=u,file=indatsize,status='old',form='unformatted', access='stream', action='read')
read(u) lx1in,lx2in,lx3in
close(u)
print *, 'Input file has size:  ',lx1in,lx2in,lx3in
print *, 'Target grid structure has size',lx1,lx2,lx3all

if (flagswap==1) then
  print *, '2D simulations grid detected, swapping input file dimension sizes and permuting input arrays'
  lx3in=lx2in
  lx2in=1
end if

if (.not. (lx1==lx1in .and. lx2==lx2in .and. lx3all==lx3in)) then
  error stop '!!!The input data must be the same size as the grid which you are running the simulation on' // & 
       '- use a script to interpolate up/down to the simulation grid'
end if

call h5f%initialize(h5fn, status='old', action='r')

if (flagswap/=1) then
  call h5f%get('nsall', statetmp)
  if(any(shape(statetmp) /= [lx1,lx2,lx3all,lsp])) error stop 'wrong dimensions read from '//h5fn
  nsall(1:lx1,1:lx2,1:lx3all,1:lsp) = statetmp

  call h5f%get('vs1all', statetmp)
  vs1all(1:lx1,1:lx2,1:lx3all,1:lsp) = statetmp

  call h5f%get('Tsall', statetmp)
  Tsall(1:lx1,1:lx2,1:lx3all,1:lsp) = statetmp
else
  !print *, shape(statetmp),shape(nsall)

  call h5f%get('nsall', statetmp)
  if(any(shape(statetmp) /= [lx1,lx3all,lx2,lsp])) error stop 'wrong dimensions read from '//h5fn
  nsall(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])

  call h5f%get('vs1all', statetmp)
  vs1all(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])

  call h5f%get('Tsall', statetmp)
  Tsall(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])    
  !! permute the dimensions so that 2D runs are parallelized

end if

call h5f%finalize()

print *, 'Done gathering input...'


!> USER SUPPLIED FUNCTION TO TAKE A REFERENCE PROFILE AND CREATE INITIAL CONDITIONS FOR ENTIRE GRID.  
!> ASSUMING THAT THE INPUT DATA ARE EXACTLY THE CORRECT SIZE (AS IS THE CASE WITH FILE INPUT) THIS IS NOW SUPERFLUOUS
print *, 'Done setting initial conditions...'
print *, 'Min/max input density:  ',     minval(nsall(:,:,:,7)),  maxval(nsall(:,:,:,7))
print *, 'Min/max input velocity:  ',    minval(vs1all(:,:,:,:)), maxval(vs1all(:,:,:,:))
print *, 'Min/max input temperature:  ', minval(Tsall(:,:,:,:)),  maxval(Tsall(:,:,:,:))


!> ROOT BROADCASTS IC DATA TO WORKERS
call cpu_time(tstart)
call bcast_send(nsall,tagns,ns)
call bcast_send(vs1all,tagvs1,vs1)
call bcast_send(Tsall,tagTs,Ts)
call cpu_time(tfin)
print *, 'Done sending ICs to workers...  CPU elapsed time:  ',tfin-tstart

end procedure input_root_mpi


end submodule readhdf5
