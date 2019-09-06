program test_diffusion1D

!----------------------------------------------------------------------------
!-------Solve a time-dependent heat equation in 1D.  See GEMINI-docs repo for
!-------a description of the specific problem solved here
!----------------------------------------------------------------------------

use phys_consts, only: wp,pi
use diffusion
implicit none

integer, parameter :: npts=256,lt=20*5
character(*), parameter :: outfile='test_diffusion1d.dat'

real(wp), dimension(npts) :: v1,dx1i
real(wp), dimension(-1:npts+2) :: x1,Ts,Tstrue
real(wp), dimension(npts) :: lambda,A,B,C,D,E
real(wp), dimension(npts+1) :: x1i
real(wp), dimension(0:npts+2) :: dx1
integer :: lx1,it,ix1,u
real(wp) :: t=0.0,dt
real(wp) :: Tsminx1,Tsmaxx1


!! create a grid for the calculation
x1=[ (real(ix1,wp)/real(npts,wp), ix1=-2,npts+1) ]
lx1=npts   !exclude ghost cells in count
dx1=x1(0:lx1+2)-x1(-1:lx1+1)
x1i(1:lx1+1)=0.5*(x1(0:lx1)+x1(1:lx1+1))
dx1i=x1i(2:lx1+1)-x1i(1:lx1)


!! write the time, space length adn spatial grid to a file
print *,'writing ',outfile
open(newunit=u,file=outfile,status='replace')
write(u,*) lt
write(u,*) lx1
call writearray(u,x1)


!! initial conditions
Ts(-1:lx1+2)=sin(2.0_wp*pi*x1(-1:lx1+2))+sin(8.0_wp*pi*x1(-1:lx1+2))
lambda(:)=1.0_wp     !thermal conductivity


!! typical diffusion time, make our time step a fraction of this
!dt=maxval(dx1)**2/maxval(lambda)
dt=0.05*1/8.0_wp**2/pi**2/maxval(lambda)


!! time interations
do it=1,lt
  !time step
  t=t+dt

  !boundary values
  Tsminx1=0.0
  Tsmaxx1=0.0

  !diffuse
  A(:)=0.0
  B(:)=0.0
  C(:)=1.0_wp
  D(:)=lambda(:)
  E(:)=0.0
  Ts(1:lx1)=backEuler1D(Ts(1:lx1),A,B,C,D,E,Tsminx1,Tsmaxx1,dt,dx1,dx1i)

  !compute analytical solution to compare
  Tstrue(1:lx1)=exp(-4.0_wp*pi**2*lambda*t)*sin(2.0_wp*pi*x1(1:lx1))+exp(-64.0_wp*pi**2*lambda*t)*sin(8.0_wp*pi*x1(1:lx1))

  !output
  write(u,*) t
  call writearray(u,Ts(1:lx1))
  call writearray(u,Tstrue(1:lx1))
end do


!! close the file
close(u)

contains

  subroutine writearray(u,array)
    integer, intent(in) :: u
    real(wp), dimension(:), intent(in) :: array
    
    integer :: k

    do k=1,size(array)
      write(u,*) array(k)
    end do
  end subroutine writearray

!
!  subroutine write2Darray(u,array)
!    integer, intent(in) :: u
!    real(wp), dimension(:,:), intent(in) :: array
!    
!    integer :: k1,k2
!
!    do k1=1,size(array,1)
!      write(u,'(f8.0)') (array(k1,k2), k2=1,size(array,2))
!    end do
!  end subroutine write2Darray
!

end program test_diffusion1D
