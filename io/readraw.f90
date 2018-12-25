submodule (io) readraw

implicit none

contains


module procedure input_root_currents
!! READS, AS INPUT, A FILE GENERATED BY THE GEMINI.f90 PROGRAM

real(wp), dimension(:,:,:), allocatable :: tmparray3D
real(wp), dimension(:,:,:,:), allocatable :: tmparray4D
character(:), allocatable :: filenamefull
real(wp), dimension(:,:,:), allocatable :: J1all,J2all,J3all
real(wp), dimension(:,:,:), allocatable :: tmpswap
real(wp) :: tmpdate
integer :: u


!>  CHECK TO MAKE SURE WE ACTUALLY HAVE THE DATA WE NEED TO DO THE MAG COMPUTATIONS.
if (flagoutput==3) error stop '  !!!I need current densities in the output to compute magnetic fields!!!'


!> FORM THE INPUT FILE NAME
filenamefull=date_filename(outdir,ymd,UTsec)
print *, 'Input file name for current densities:  ',filenamefull
open(newunit=u,file=filenamefull,status='old',form='unformatted',access='stream',action='read')
read(u) tmpdate
print *, 'File year:  ',tmpdate
read(u) tmpdate
print *, 'File month:  ',tmpdate
read(u) tmpdate
print *, 'File day:  ',tmpdate
read(u) tmpdate
print *, 'File UThrs:  ',tmpdate


!> LOAD THE DATA
if (flagoutput==2) then    !the simulation data have only averaged plasma parameters
  print *, '  Reading in files containing averaged plasma parameters of size:  ',lx1*lx2*lx3all
  allocate(tmparray3D(lx1,lx2,lx3all))
  !MZ:  I've found what I'd consider to be a gfortran bug here.  If I read
  !in a flat array (i.e. a 1D set of data) I hit EOF, according to runtime
  !error, well before I'm actually out of data this happens with a 20GB
  !input file for not for a 3GB input file...  This doesn't happen when I do
  !the reading with 3D arrays.  
  read(u) tmparray3D    !ne - could be done with some judicious fseeking...
  read(u) tmparray3D    !vi
  read(u) tmparray3D    !Ti
  read(u) tmparray3D    !Te
  deallocate(tmparray3D)
else    !full output parameters are in the output files
  print *, '  Reading in files containing full plasma parameters of size:  ',lx1*lx2*lx3all*lsp
  allocate(tmparray4D(lx1,lx2,lx3all,lsp))
  read(u) tmparray4D
  read(u) tmparray4D
  read(u) tmparray4D
  deallocate(tmparray4D)
end if


!> PERMUTE THE ARRAYS IF NECESSARY
print *, '  File fast-forward done, now reading currents...'
allocate(J1all(lx1,lx2,lx3all),J2all(lx1,lx2,lx3all),J3all(lx1,lx2,lx3all))
if (flagswap==1) then
  allocate(tmpswap(lx1,lx3all,lx2))
  read(u) tmpswap
  J1all=reshape(tmpswap,[lx1,lx2,lx3all],order=[1,3,2])
  read(u) tmpswap
  J2all=reshape(tmpswap,[lx1,lx2,lx3all],order=[1,3,2])
  read(u) tmpswap
  J3all=reshape(tmpswap,[lx1,lx2,lx3all],order=[1,3,2])
  deallocate(tmpswap)
else    !no need to permute dimensions for 3D simulations
  read(u) J1all,J2all,J3all
end if
print *, 'Min/max current data:  ',minval(J1all),maxval(J1all),minval(J2all),maxval(J2all),minval(J3all),maxval(J3all)


!> DISTRIBUTE DATA TO WORKERS AND TAKE A PIECE FOR ROOT
call bcast_send(J1all,tagJ1,J1)
call bcast_send(J2all,tagJ2,J2)
call bcast_send(J3all,tagJ3,J3)

end procedure input_root_currents


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
real(wp) :: tin
real(wp), dimension(3) :: ymdtmp

real(wp) :: tstart,tfin    

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

open(newunit=u,file=indatfile,status='old',form='unformatted', access='stream', action='read')
read(u) ymdtmp,tin

if (flagswap/=1) then
  read(u) nsall(1:lx1,1:lx2,1:lx3all,1:lsp)
  read(u) vs1all(1:lx1,1:lx2,1:lx3all,1:lsp)
  read(u) Tsall(1:lx1,1:lx2,1:lx3all,1:lsp)
else
  allocate(statetmp(lx1,lx3all,lx2,lsp))
  !print *, shape(statetmp),shape(nsall)

  read(u) statetmp
  nsall(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])
  read(u) statetmp
  vs1all(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])

  read(u) statetmp
  Tsall(1:lx1,1:lx2,1:lx3all,1:lsp)=reshape(statetmp,[lx1,lx2,lx3all,lsp],order=[1,3,2,4])    !permute the dimensions so that 2D runs are parallelized
  deallocate(statetmp)
end if
close(u)
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


end submodule readraw
