module io

!! HANDLES INPUT AND OUTPUT OF PLASMA STATE PARAMETERS (NOT GRID INPUTS)
use, intrinsic :: iso_fortran_env, only: stderr=>error_unit, compiler_version, compiler_options
use, intrinsic :: ieee_arithmetic, only: ieee_is_nan, ieee_value, ieee_quiet_nan
use phys_consts, only : kB,ms,pi,lsp,wp,lwave
use fsutils, only: expanduser
use calculus
use mpimod
use grid, only : gridflag,flagswap,lx1,lx2,lx3,lx3all

implicit none

interface
module subroutine create_outdir(outdir,infile,indatsize,indatgrid,flagdneu,sourcedir,flagprecfile,precdir,flagE0file,E0dir)
character(*), intent(in) :: outdir, & !< command line argument output directory
                            infile, & !< command line argument input file
                            indatsize,indatgrid,sourcedir, precdir,E0dir
integer, intent(in) :: flagdneu, flagprecfile, flagE0file
end subroutine create_outdir

module subroutine create_outdir_mag(outdir,fieldpointfile)
character(*), intent(in) :: outdir
character(*), intent(in) :: fieldpointfile
end subroutine create_outdir_mag

module subroutine create_outdir_aur(outdir)
character(*), intent(in) :: outdir
end subroutine create_outdir_aur

module subroutine output_root_stream_mpi(outdir,flagoutput,ymd,UTsec,vs2,vs3,ns,vs1,Ts,Phiall,J1,J2,J3)
character(*), intent(in) :: outdir
integer, intent(in) :: flagoutput

integer, dimension(3), intent(in) :: ymd
real(wp), intent(in) :: UTsec
real(wp), dimension(-1:,-1:,-1:,:), intent(in) :: vs2,vs3,ns,vs1,Ts    

real(wp), dimension(:,:,:), intent(in) :: Phiall
real(wp), dimension(:,:,:), intent(in) :: J1,J2,J3
end subroutine output_root_stream_mpi

module subroutine output_magfields(outdir,ymd,UTsec,Br,Btheta,Bphi)
character(*), intent(in) :: outdir
integer, intent(in) :: ymd(3)
real(wp), intent(in) :: UTsec
real(wp), dimension(:), intent(in)  :: Br,Btheta,Bphi
end subroutine output_magfields

module subroutine output_aur_root(outdir,flagglow,ymd,UTsec,iver)
character(*), intent(in) :: outdir
integer, intent(in) :: flagglow, ymd(3)
real(wp), intent(in) :: UTsec
real(wp), dimension(:,:,:), intent(in) :: iver
end subroutine output_aur_root

module subroutine input_root_currents(outdir,flagoutput,ymd,UTsec,J1,J2,J3)
character(*), intent(in) :: outdir
integer, intent(in) :: flagoutput
integer, dimension(3), intent(in) :: ymd
real(wp), intent(in) :: UTsec
real(wp), dimension(:,:,:), intent(out) :: J1,J2,J3
end subroutine input_root_currents

module subroutine input_root_mpi(x1,x2,x3all,indatsize,ns,vs1,Ts)
real(wp), dimension(-1:), intent(in) :: x1, x2, x3all
character(*), intent(in) :: indatsize
real(wp), dimension(-1:,-1:,-1:,:), intent(out) :: ns,vs1,Ts
end subroutine input_root_mpi

end interface

!> NONE OF THESE VARIABLES SHOULD BE ACCESSED BY PROCEDURES OUTSIDE THIS MODULE
character(:), allocatable, private :: indatfile                    
!! initial condition data files from input configuration file

contains


subroutine read_configfile(infile,ymd,UTsec0,tdur,dtout,activ,tcfl,Teinf,potsolve,flagperiodic, &
                 flagoutput,flagcap,indatsize,indatgrid,flagdneu,interptype, &
                 sourcemlat,sourcemlon,dtneu,drhon,dzn,sourcedir,flagprecfile,dtprec,precdir, &
                 flagE0file,dtE0,E0dir,flagglow,dtglow,dtglowout)
!! READS THE INPUT CONFIGURAITON FILE ANDE ASSIGNS VARIABLES FOR FILENAMES, SIZES, ETC.

character(*), intent(in) :: infile
integer, dimension(3), intent(out):: ymd
real(wp), intent(out) :: UTsec0
real(wp), intent(out) :: tdur
real(wp), intent(out) :: dtout
real(wp), dimension(3), intent(out) :: activ
real(wp), intent(out) :: tcfl
real(wp), intent(out) :: Teinf
integer, intent(out) :: potsolve, flagperiodic, flagoutput, flagcap 
integer, intent(out) :: flagdneu
integer, intent(out) :: interptype
real(wp), intent(out) :: sourcemlat,sourcemlon
real(wp), intent(out) :: dtneu
real(wp), intent(out) :: drhon,dzn
integer, intent(out) :: flagprecfile
real(wp), intent(out) :: dtprec
character(:), allocatable, intent(out) :: indatsize,indatgrid, sourcedir, precdir, E0dir
integer, intent(out) :: flagE0file
real(wp), intent(out) :: dtE0
integer, intent(out) :: flagglow
real(wp), intent(out) :: dtglow, dtglowout

character(256) :: buf
integer :: u
real(wp) :: NaN

NaN = ieee_value(0._wp, ieee_quiet_nan)

!> READ CONFIG.DAT FILE FOR THIS SIMULATION
open(newunit=u, file=infile, status='old', action='read')
read(u,*) ymd(3),ymd(2),ymd(1)
read(u,*) UTsec0
read(u,*) tdur
read(u,*) dtout
read(u,*) activ(1),activ(2),activ(3)
read(u,*) tcfl
read(u,*) Teinf
read(u,*) potsolve
read(u,*) flagperiodic
read(u,*) flagoutput
read(u,*) flagcap
read(u,'(a256)') buf  
!! format specifier needed, else it reads just one character
indatsize = expanduser(buf)
read(u,'(a256)') buf
indatgrid = expanduser(buf)
read(u,'(a256)') buf
indatfile = expanduser(buf)

!> PRINT SOME DIAGNOSIC INFO FROM ROOT
if (myid==0) then
  print '(A,I6,A1,I0.2,A1,I0.2)', infile//': simulation ymd is:  ',ymd(1),'/',ymd(2),'/',ymd(3)
  print '(A51,F10.3)', 'start time is:  ',UTsec0
  print '(A51,F10.3)', 'duration is:  ',tdur
  print '(A51,F10.3)', 'output every:  ',dtout
  print *, '...using input data files:  '
  print *, '  ',indatsize
  print *, '  ',indatgrid
  print *, '  ',indatfile
end if


!> NEUTRAL PERTURBATION INPUT INFORMATION
read(u,*) flagdneu
if( flagdneu==1) then
  read(u,*) interptype
  read(u,*) sourcemlat,sourcemlon
  read(u,*) dtneu
  read(u,*) drhon,dzn
  read(u,'(A256)') buf
  sourcedir = expanduser(buf)
  if (myid ==0) then
    print *, 'Neutral disturbance mlat,mlon:  ',sourcemlat,sourcemlon
    print *, 'Neutral disturbance cadence (s):  ',dtneu
    print *, 'Neutral grid resolution (m):  ',drhon,dzn
    print *, 'Neutral disturbance data files located in directory:  ',sourcedir
  end if
else                              
!! just set it to something
  interptype=0
  sourcemlat=0._wp; sourcemlon=0._wp;
  dtneu=0._wp
  drhon=0._wp; dzn=0._wp;
  sourcedir=''
end if

!> PRECIPITATION FILE INPUT INFORMATION
read(u,*) flagprecfile
if (flagprecfile==1) then    
!! get the location of the precipitation input files
  read(u,*) dtprec

  read(u,'(A256)') buf
  precdir = expanduser(buf)
  
  if (myid==0) then
    print '(A,F10.3)', 'Precipitation file input cadence (s):  ',dtprec
    print *, 'Precipitation file input source directory:  '//precdir
  end if
else                         
!! just set results to something
  dtprec=0._wp
  precdir=''
end if

!> ELECTRIC FIELD FILE INPUT INFORMATION
read(u,*) flagE0file
if (flagE0file==1) then    
!! get the location of the precipitation input files
  read(u,*) dtE0

  read(u,'(a256)') buf
  E0dir = expanduser(buf)

  if (myid==0) then
    print *, 'Electric field file input cadence (s):  ',dtE0
    print *, 'Electric field file input source directory:  '//E0dir
  end if
else                         !just set results to something
  dtE0=0._wp
  E0dir=''
end if

!> GLOW ELECTRON TRANSPORT INFORMATION
read(u,*) flagglow
if (flagglow==1) then
  read(u,*) dtglow
  read(u,*) dtglowout
  if (myid == 0) then
    print *, 'GLOW enabled for auroral emission calculations.'
    print *, 'GLOW electron transport calculation cadence (s): ', dtglow
    print *, 'GLOW auroral emission output cadence (s): ', dtglowout
  end if
else
  dtglow=NaN
  dtglowout=NaN
end if

close(u)
end subroutine read_configfile


subroutine input_plasma(x1,x2,x3all,indatsize,ns,vs1,Ts)

!! A BASIC WRAPPER FOR THE ROOT AND WORKER INPUT FUNCTIONS
!! BOTH ROOT AND WORKERS CALL THIS PROCEDURE SO UNALLOCATED
!! VARIABLES MUST BE DECLARED AS ALLOCATABLE, INTENT(INOUT)

real(wp), dimension(-1:), intent(in) :: x1, x2, x3all
character(*), intent(in) :: indatsize

real(wp), dimension(-1:,-1:,-1:,:), intent(out) :: ns,vs1,Ts


if (myid==0) then
  !ROOT FINDS/CALCULATES INITIAL CONDITIONS AND SENDS TO WORKERS
  print *, 'Assembling initial condition on root using '//indatsize//' '//indatfile
  call input_root_mpi(x1,x2,x3all,indatsize,ns,vs1,Ts)
else
  !WORKERS RECEIVE THE IC DATA FROM ROOT
  call input_workers_mpi(ns,vs1,Ts)
end if

end subroutine input_plasma


subroutine input_workers_mpi(ns,vs1,Ts)

!------------------------------------------------------------
!-------RECEIVE INITIAL CONDITIONS FROM ROOT PROCESS
!------------------------------------------------------------

real(wp), dimension(-1:,-1:,-1:,:), intent(out) :: ns,vs1,Ts     

call bcast_recv(ns,tagns)
call bcast_recv(vs1,tagvs1)
call bcast_recv(Ts,tagTs)

end subroutine input_workers_mpi


subroutine input_plasma_currents(outdir,flagoutput,ymd,UTsec,J1,J2,J3)

!! READS, AS INPUT, A FILE GENERATED BY THE GEMINI.F90 PROGRAM.
!! THIS SUBROUTINE IS A WRAPPER FOR SEPARATE ROOT/WORKER CALLS

character(*), intent(in) :: outdir
integer, intent(in) :: flagoutput
integer, dimension(3), intent(in) :: ymd
real(wp), intent(in) :: UTsec
real(wp), dimension(:,:,:), intent(out) :: J1,J2,J3


if (myid==0) then
  !> ROOT FINDS/CALCULATES INITIAL CONDITIONS AND SENDS TO WORKERS
  print *, 'Assembling current density data on root...  '
  call input_root_currents(outdir,flagoutput,ymd,UTsec,J1,J2,J3)
else
  !> WORKERS RECEIVE THE IC DATA FROM ROOT
  call input_workers_currents(J1,J2,J3)
end if

end subroutine input_plasma_currents


subroutine input_workers_currents(J1,J2,J3)

!! WORKER INPUT FUNCTIONS FOR GETTING CURRENT DENSITIES

real(wp), dimension(:,:,:), intent(out) :: J1,J2,J3

!> ALL WE HAVE TO DO IS WAIT TO RECEIVE OUR PIECE OF DATA FROM ROOT
call bcast_recv(J1,tagJ1)
call bcast_recv(J2,tagJ2)
call bcast_recv(J3,tagJ3)

end subroutine input_workers_currents


subroutine output_plasma(outdir,flagoutput,ymd,UTsec,vs2,vs3,ns,vs1,Ts,Phiall,J1,J2,J3)

!------------------------------------------------------------
!-------A BASIC WRAPPER FOR THE ROOT AND WORKER OUTPUT FUNCTIONS
!-------BOTH ROOT AND WORKERS CALL THIS PROCEDURE SO UNALLOCATED
!-------VARIABLES MUST BE DECLARED AS ALLOCATABLE, INTENT(INOUT)
!------------------------------------------------------------

character(*), intent(in) :: outdir
integer, intent(in) :: flagoutput

integer, dimension(3), intent(in) :: ymd
real(wp), intent(in) :: UTsec
real(wp), dimension(-1:,-1:,-1:,:), intent(in) :: vs2,vs3,ns,vs1,Ts

real(wp), dimension(:,:,:), allocatable, intent(inout) :: Phiall     !these jokers may not be allocated, but this is allowed as of f2003
real(wp), dimension(:,:,:), intent(in) :: J1,J2,J3


if (myid/=0) then
  call output_workers_mpi(vs2,vs3,ns,vs1,Ts,J1,J2,J3)
else
  call output_root_stream_mpi(outdir,flagoutput,ymd,UTsec,vs2,vs3,ns,vs1,Ts,Phiall,J1,J2,J3)    !only option that works with >2GB files
end if  

end subroutine output_plasma


subroutine output_workers_mpi(vs2,vs3,ns,vs1,Ts,J1,J2,J3)

!------------------------------------------------------------
!-------SEND COMPLETE DATA FROM WORKERS TO ROOT PROCESS FOR OUTPUT.  
!-------STATE VARS ARE EXPECTED TO INCLUDE GHOST CELLS
!------------------------------------------------------------

real(wp), dimension(-1:,-1:,-1:,:), intent(in) :: vs2,vs3,ns,vs1,Ts     
real(wp), dimension(:,:,:), intent(in) :: J1,J2,J3

integer :: lx1,lx2,lx3,lx3all,isp
real(wp), dimension(1:size(ns,1)-4,1:size(ns,2)-4,1:size(ns,3)-4) :: v2avg,v3avg


!SYSTEM SIZES (W/O GHOST CELLS)
lx1=size(ns,1)-4
lx2=size(ns,2)-4
lx3=size(ns,3)-4


!ONLY AVERAGE DRIFTS PERP TO B NEEDED FOR OUTPUT
v2avg=sum(ns(1:lx1,1:lx2,1:lx3,1:lsp-1)*vs2(1:lx1,1:lx2,1:lx3,1:lsp-1),4)
v2avg=v2avg/ns(1:lx1,1:lx2,1:lx3,lsp)    !compute averages for output.
v3avg=sum(ns(1:lx1,1:lx2,1:lx3,1:lsp-1)*vs3(1:lx1,1:lx2,1:lx3,1:lsp-1),4)
v3avg=v3avg/ns(1:lx1,1:lx2,1:lx3,lsp)


!SEND MY GRID DATA TO THE ROOT PROCESS
call gather_send(v2avg,tagv2)
call gather_send(v3avg,tagv3)
call gather_send(ns,tagns)
call gather_send(vs1,tagvs1)
call gather_send(Ts,tagTs)


!------- SEND ELECTRODYNAMIC PARAMETERS TO ROOT
call gather_send(J1,tagJ1)
call gather_send(J2,tagJ2)
call gather_send(J3,tagJ3)  

end subroutine output_workers_mpi


subroutine output_aur(outdir,flagglow,ymd,UTsec,iver)
character(*), intent(in) :: outdir
integer, intent(in) :: flagglow

integer, dimension(3), intent(in) :: ymd
real(wp), intent(in) :: UTsec

real(wp), dimension(:,:,:), intent(in) :: iver
!! A BASIC WRAPPER FOR THE ROOT AND WORKER OUTPUT FUNCTIONS BOTH ROOT AND WORKERS CALL THIS PROCEDURE
!! SO UNALLOCATED VARIABLES MUST BE DECLARED AS ALLOCATABLE, INTENT(INOUT)

if (myid/=0) then
  call output_aur_workers(iver)
else
  call output_aur_root(outdir,flagglow,ymd,UTsec,iver)
end if

end subroutine output_aur


subroutine output_aur_workers(iver)
real(wp), dimension(:,:,:), intent(in) :: iver
!! SEND COMPLETE DATA FROM WORKERS TO ROOT PROCESS FOR OUTPUT.  NO GHOST CELLS (I HOPE)

real(wp), dimension(1:lx2,1:lwave,1:lx3) :: ivertmp

ivertmp=reshape(iver,[lx2,lwave,lx3],order=[1,3,2])

!------- SEND AURORA PARAMETERS TO ROOT
call gather_send(ivertmp,tagAur)

end subroutine output_aur_workers


pure function date_filename(outdir,ymd,UTsec)
!! GENERATE A FILENAME STRING OUT OF A GIVEN DATE/TIME

character(*), intent(in) :: outdir
integer, intent(in) :: ymd(3)
real(wp), intent(in) :: UTsec
character(:), allocatable :: date_filename
character(25) :: fn


!> UTC second (float, 0.0 .. 86400) 
write(fn,'(i4,2i0.2,a1,f12.6,a4)') ymd, '_', UTsec, '.dat'

!> assemble
date_filename = outdir // '/' // fn

end function date_filename


subroutine gitlog(logpath)
!! logs git branch, hash to file

character(*), intent(in) :: logpath

!> write branch
call execute_command_line('git rev-parse --abbrev-ref HEAD > '// logpath)

!> write hash
call execute_command_line('git rev-parse --short HEAD >> '// logpath)

!> write changed filenames
call execute_command_line('git status --porcelain >> '// logpath)

end subroutine gitlog


subroutine compiler_log(logpath)

character(*), intent(in) :: logpath
integer :: u

open(newunit=u, file=logpath, status='unknown', action='write')

write(u,'(A,/)') compiler_version()
write(u,'(A)') compiler_options()

close(u)

end subroutine compiler_log

end module io
