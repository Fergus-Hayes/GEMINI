program test_potential2D

!------------------------------------------------------------
!-------SOLVE LAPLACE'S EQUATION IN 2D USING MUMPS
!------------------------------------------------------------

implicit none
include 'mpif.h'
include 'dmumps_struc.h'

type (DMUMPS_STRUC) mumps_par
integer :: ierr

integer, parameter :: npts1=250,npts2=250,outunit=42
integer, parameter :: lk=npts1*npts2, lent=5*(npts1-2)*(npts2-2)+2*npts1+2*(npts2-2)
integer :: ix1,ix2,lx1,lx2
integer :: iPhi,ient
integer, dimension(:), allocatable :: ir,ic
real(8), dimension(:), allocatable :: M
real(8), dimension(:), allocatable :: b
real(8) :: dx1
real(8), dimension(npts1) :: Vleft,Vright
real(8), dimension(npts2) :: Vbottom,Vtop
real(8), dimension(:,:), allocatable ::  Mfull
real(8) :: tstart,tfin


!------------------------------------------------------------
!-------DEFINE A MATRIX USING SPARSE STORAGE (CENTRALIZED
!-------ASSEMBLED MATRIX INPUT, SEE SECTION 4.5 OF MUMPS USER
!-------GUIDE).
!------------------------------------------------------------
allocate(ir(lent),ic(lent),M(lent),b(lk))
lx1=npts1
lx2=npts2

dx1=1.0/npts1           !scale dx so the domain of problem is [0,1]

Vleft(:)=0
Vright(:)=0
Vbottom(:)=1.0
Vtop(:)=0

M(:)=0.0
b(:)=0.0
ient=1


!LOAD UP MATRIX ELEMENTS
do ix2=1,lx2
  do ix1=1,lx1
    iPhi=lx1*(ix2-1)+ix1     !linear index referencing Phi(ix1,ix2) as a column vector.  Also row of big matrix

    if (ix1==1) then          !BOTTOM GRID POINTS + CORNER
      ir(ient)=iPhi
      ic(ient)=iPhi
      M(ient)=1.0
      b(iPhi)=Vbottom(ix2)
      ient=ient+1
    elseif (ix1==lx1) then    !TOP GRID POINTS + CORNER
      ir(ient)=iPhi
      ic(ient)=iPhi
      M(ient)=1.0
      b(iPhi)=Vtop(ix2)
      ient=ient+1
    elseif (ix2==1) then      !LEFT BOUNDARY
      ir(ient)=iPhi
      ic(ient)=iPhi  
      M(ient)=1.0
      b(iPhi)=Vleft(ix1)
      ient=ient+1
    elseif (ix2==lx2) then    !RIGHT BOUNDARY
      ir(ient)=iPhi
      ic(ient)=iPhi
      M(ient)=1.0
      b(iPhi)=Vright(ix1)
      ient=ient+1
    else                      !INTERIOR
      !ix1,ix2-1 grid point in ix1,ix2 equation
      ir(ient)=iPhi
      ic(ient)=iPhi-lx1
      M(ient)=1.0
      ient=ient+1

      !ix1-1,ix2 grid point
      ir(ient)=iPhi
      ic(ient)=iPhi-1
      M(ient)=1.0
      ient=ient+1

      !ix1,ix2 grid point
      ir(ient)=iPhi
      ic(ient)=iPhi
      M(ient)=-4.0
      ient=ient+1

      !ix1+1,ix2 grid point
      ir(ient)=iPhi
      ic(ient)=iPhi+1
      M(ient)=1.0
      ient=ient+1

      !ix1,ix2+1 grid point
      ir(ient)=iPhi
      ic(ient)=iPhi+lx1
      M(ient)=1.0
      ient=ient+1
    end if
  end do
end do


!CORRECT FOR DX /= 1
b=b*dx1**2


!OUTPUT FULL MATRIX FOR DEBUGGING IF ITS NOT TOO BIG (ZZZ --> CAN BE COMMENTED OUT)
open(outunit,file='test_potential2D.dat',status='replace')
write(outunit,*) lx1,lx2
write(outunit,*) dx1
if (lk<100) then
  allocate(Mfull(lk,lk))
  Mfull(:,:)=0.0
  do ient=1,size(ir)
    Mfull(ir(ient),ic(ient))=M(ient)
  end do
  call write2Darray(outunit,Mfull)
  call writearray(outunit,b)
  deallocate(Mfull)
end if


!------------------------------------------------------------
!-------DO SOME STUFF TO CALL MUMPS
!------------------------------------------------------------
call MPI_INIT(IERR)


! Define a communicator for the package.
mumps_par%COMM = MPI_COMM_WORLD


!Initialize an instance of the package
!for L U factorization (sym = 0, with working host)
mumps_par%JOB = -1
mumps_par%SYM = 0
mumps_par%PAR = 1
call DMUMPS(mumps_par)


!Define problem on the host (processor 0)
if ( mumps_par%MYID .eq. 0 ) then
  mumps_par%N=lk
  mumps_par%NZ=lent
  allocate( mumps_par%IRN ( mumps_par%NZ ) )
  allocate( mumps_par%JCN ( mumps_par%NZ ) )
  allocate( mumps_par%A( mumps_par%NZ ) )
  allocate( mumps_par%RHS ( mumps_par%N  ) )
  mumps_par%IRN=ir
  mumps_par%JCN=ic
  mumps_par%A=M
  mumps_par%RHS=b
end if


!Call package for solution
mumps_par%JOB = 6
call cpu_time(tstart)
call DMUMPS(mumps_par)
call cpu_time(tfin)
write(*,*) 'Solve took ',tfin-tstart,' seconds...'


!Solution has been assembled on the host
if ( mumps_par%MYID .eq. 0 ) then
  call writearray(outunit,mumps_par%RHS/dx1**2)    !rescale by dx**2 to physical values
end if
close(outunit)


!Deallocate user data
if ( mumps_par%MYID .eq. 0 ) then
  deallocate( mumps_par%IRN )
  deallocate( mumps_par%JCN )
  deallocate( mumps_par%A   )
  deallocate( mumps_par%RHS )
end if
deallocate(ir,ic,M,b)


!Destroy the instance (deallocate internal data structures)
mumps_par%JOB = -2
call DMUMPS(mumps_par)
call MPI_FINALIZE(IERR)



contains

  subroutine writearray(fileunit,array)
    integer, intent(in) :: fileunit
    real(8), dimension(:), intent(in) :: array
    
    integer :: k

    do k=1,size(array)
      write(fileunit,*) array(k)
    end do
  end subroutine writearray


  subroutine write2Darray(fileunit,array)
    integer, intent(in) :: fileunit
    real(8), dimension(:,:), intent(in) :: array
    
    integer :: k1,k2

    do k1=1,size(array,1)
      write(fileunit,'(f4.0)') (array(k1,k2), k2=1,size(array,2))
    end do
  end subroutine write2Darray

end program test_potential2D
