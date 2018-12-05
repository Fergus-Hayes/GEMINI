module precipBCs_mod
  use, intrinsic:: iso_fortran_env, only: stderr=>error_unit
  use phys_consts, only: pi,wp
  use grid, only : curvmesh,lx1,lx2,lx3,lx3all
  use interpolation, only : interp1,interp2
  use io, only : date_filename
  use temporal, only : dateinc
  use mpimod

implicit none

!ALL OF THE FOLLOWING MODULE-SCOPE ARRAYS ARE USED FOR INTERPOLATING PRECIPITATION INPUT FILES (IF USED)
real(wp), dimension(:), allocatable, private :: mlonp
real(wp), dimension(:), allocatable, private :: mlatp    !coordinates of precipitation data
integer, private :: llon,llat

real(wp), dimension(:,:), allocatable, private :: Qp,E0p    !total energy flux and char. energy of input data
real(wp), dimension(:), allocatable, private :: precdatp    !needed when a 1D interpolation is to be done, i.e. when there is 1D sourde data

real(wp), dimension(:), allocatable, private :: mloni    !flat list of mlat,mlon locations on grid that we need to interpolate onto
real(wp), dimension(:), allocatable, private :: mlati

real(wp), dimension(:,:), allocatable, private :: Qiprev,E0iprev,Qinext,E0inext    !interpolated in space energy flux and char. en.

integer, dimension(3), private :: ymdprev,ymdnext   !dates for interpolated data
real(wp), private :: UTsecprev,UTsecnext
real(wp), private :: tprev,tnext


contains


  subroutine precipBCs_fileinput(dt,dtprec,t,ymd,UTsec,precdir,x,W0,PhiWmWm2)

    real(wp), intent(in) :: dt,dtprec
    real(wp), intent(in) :: t
    integer, dimension(3), intent(in) :: ymd    !date for which we wish to calculate perturbations
    real(wp), intent(in) :: UTsec
    real(wp), dimension(:,:,:), intent(out) :: W0,PhiWmWm2    !last dimension is the number of particle populations

    character(*), intent(in) :: precdir       !directory where neutral simulation data is kept
    type(curvmesh) :: x

    character(512) :: buf
    character(:), allocatable :: sizefn, gridfn, precfn
    integer :: ios, u
    integer :: iid,iflat,ix2,ix3

    real(wp) :: UTsectmp
    integer, dimension(3) :: ymdtmp

    real(wp), dimension(lx2*lx3) :: parami
    real(wp), dimension(lx2,lx3) :: slope,Qinow,E0inow
    real(wp) :: W0pk,PhiWpk


    if(t+dt/2d0>=tnext) then    !need to load a new file
      if ( .not. allocated(mlonp)) then    !need to read in the grid data from input file
        ymdprev=ymd
        UTsecprev=UTsec
        ymdnext=ymdprev
        UTsecnext=UTsecprev

        if (myid==0) then    !root process
          !READ IN THE GRID
          write(buf,*) precdir,'/simsize.dat'; sizefn = trim(adjustl(buf))  ! NOTE: need here trim(adjustl()) for some compilers despite doing it earlier on allocation in io.f90.
          print *, 'Inputting precipitation data size from file:  ',sizefn
          open(newunit=u,file=sizefn, status='old',form='unformatted',access='stream', action='read')
          read(u) llon,llat
          close(u)
          print *, 'Precipitation data has llon,llat size:  ',llon,llat


          !MESSAGE WORKERS WITH GRID INFO
          do iid=1,lid-1
            call mpi_send(llon,1,MPI_INTEGER,iid,tagllon,MPI_COMM_WORLD,ierr)
            call mpi_send(llat,1,MPI_INTEGER,iid,tagllat,MPI_COMM_WORLD,ierr)
          end do
          allocate(mlonp(llon),mlatp(llat))    !bit of code duplication with worker code block below...


          !IF WE HAVE SINGLETON DIMENSION THEN ALLOCATE SOME SPACE FOR A TEMP
          !ARRAY FOR INPUTTING INTO INTERP1
          if (llon==1) then
            allocate(precdatp(llat))
          elseif (llat==1) then
            allocate(precdatp(llon))
          end if


          !NOW READ THE GRID
          write(buf,*) precdir,'/simgrid.dat'; gridfn = trim(adjustl(buf)) ! NOTE: need here trim(adjustl()) for some compilers despite doing it earlier on allocation in io.f90.
          print *, 'Inputting precipitation grid from file:  ',gridfn
          open(newunit=u,file=gridfn,status='old',form='unformatted',access='stream', action='read')
          read(u) mlonp,mlatp
          close(u)
          print *, 'Precipitation data has mlon,mlat extent:  ',minval(mlonp(:)),maxval(mlonp(:)),minval(mlatp(:)), &
                                                                  maxval(mlatp(:))

          !NOW SEND THE GRID DATA
          do iid=1,lid-1
            call mpi_send(mlonp,llon,mpi_realprec,iid,tagmlon,MPI_COMM_WORLD,ierr)
            call mpi_send(mlatp,llat,mpi_realprec,iid,tagmlat,MPI_COMM_WORLD,ierr)
          end do
        else    !workers
          call mpi_recv(llon,1,MPI_INTEGER,0,tagllon,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
          call mpi_recv(llat,1,MPI_INTEGER,0,tagllat,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
          allocate(mlonp(llon),mlatp(llat)) 

          call mpi_recv(mlonp,llon,mpi_realprec,0,tagmlon,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
          call mpi_recv(mlatp,llat,mpi_realprec,0,tagmlat,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
        end if

        !SPACE TO STORE INPUT DATA
        allocate(Qp(llon,llat),E0p(llon,llat))
        allocate(Qiprev(lx2,lx3),E0iprev(lx2,lx3),Qinext(lx2,lx3),E0inext(lx2,lx3))
        Qiprev=0d0; E0iprev=100d0; Qinext=0d0; E0inext=100d0;     !these need to be initialized so that something sensible happens at the beginning

        !ALL PROCESSES NEED TO DEFINED THE OPINTS THAT THEY WILL BE INTERPOLATING ONTO
        allocate(mloni(lx2*lx3),mlati(lx2*lx3))
        do ix3=1,lx3
          do ix2=1,lx2
            iflat=(ix3-1)*lx2+ix2
            mlati(iflat)=90d0-x%theta(lx1,ix2,ix3)*180d0/pi
            mloni(iflat)=x%phi(lx1,ix2,ix3)*180d0/pi
          end do
        end do

      end if


      !GRID INFORMATION EXISTS AT THIS POINT SO START READING IN PRECIP DATA
      if (myid==0) then    !only root reads file data
        !read in the data from file
        print *, 'tprev,tnow,tnext:  ',tprev,t+dt/2d0,tnext
        ymdtmp=ymdnext
        UTsectmp=UTsecnext
        call dateinc(dtprec,ymdtmp,UTsectmp)    !get the date for "next" params
        precfn = date_filename(precdir,ymdtmp,UTsectmp)     !form the standard data filename
        print *, 'Pulling precipitation data from file:  ',precfn
        open(newunit=u,file=precfn,status='old',form='unformatted',access='stream',iostat=ios)
        if (ios==0) then    !successful read
          print *, 'Successfully located input file...'
          read(u) Qp,E0p
        else      
          error stop 'Bad input file!!!'
          !error stop 'Bad input file: '//precfn   ! made error stop per MZ, Oct 2018
          !just set everything to zero
          !write(stderr,*) 'Bad input file '//precfn//' setting everything to some default value...'
          !Qp=0d0; E0p=100d0;
        end if
        close(u)

        print *, 'Min/max values for Qp:  ',minval(pack(Qp,.true.)),maxval(pack(Qp,.true.))
        print *, 'Min/max values for E0p:  ',minval(pack(E0p,.true.)),maxval(pack(E0p,.true.))

        !send a full copy of the data to all of the workers
        do iid=1,lid-1
          call mpi_send(Qp,llon*llat,mpi_realprec,iid,tagQp,MPI_COMM_WORLD,ierr)
          call mpi_send(E0p,llon*llat,mpi_realprec,iid,tagE0p,MPI_COMM_WORLD,ierr)
        end do
      else     !workers receive data from root
        call mpi_recv(Qp,llon*llat,mpi_realprec,0,tagQp,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
        call mpi_recv(E0p,llon*llat,mpi_realprec,0,tagE0p,MPI_COMM_WORLD,MPI_STATUS_IGNORE,ierr)
      end if


      !ALL WORKERS DO SPATIAL INTERPOLATION
      if (myid==0) then
        print *, 'Initiating precipitation spatial interpolations for date:  ',ymdtmp,' ',UTsectmp
      end if
      if (llon==1) then    !source data has singleton size in the longitude dimension
        precdatp=Qp(1,:)
        parami=interp1(mlatp,precdatp,mlati)   !will work even for 2D grids, just repeats the data in the lon direction
        Qiprev=Qinext
        Qinext=reshape(parami,[lx2,lx3])

        precdatp=E0p(1,:)
        parami=interp1(mlatp,precdatp,mlati)   !will work even for 2D grids, just repeats the data in the lon direction
        E0iprev=E0inext
        E0inext=reshape(parami,[lx2,lx3])
      elseif (llat==1) then     !source is singleton in lat.
        precdatp=Qp(:,1)
        parami=interp1(mlonp,precdatp,mloni)
        Qiprev=Qinext
        Qinext=reshape(parami,[lx2,lx3])

        precdatp=E0p(:,1)
        parami=interp1(mlonp,precdatp,mloni)
        E0iprev=E0inext
        E0inext=reshape(parami,[lx2,lx3])
      else     !source data is fully 2D
        parami=interp2(mlonp,mlatp,Qp,mloni,mlati)     !interp to temp var.
        Qiprev=Qinext                       !save new pervious
        Qinext=reshape(parami,[lx2,lx3])    !overwrite next with new interpolated input

        parami=interp2(mlonp,mlatp,E0p,mloni,mlati)
        E0iprev=E0inext
        E0inext=reshape(parami,[lx2,lx3])
      end if
      if (myid==lid/2) then
        write(*,*) 'Min/max values for Qi:  ',minval(pack(Qinext,.true.)),maxval(pack(Qinext,.true.))
        write(*,*) 'Min/max values for E0i:  ',minval(pack(E0inext,.true.)),maxval(pack(E0inext,.true.))
      end if


      !UPDATE OUR CONCEPT OF PREVIOUS AND NEXT TIMES
      tprev=tnext
      UTsecprev=UTsecnext
      ymdprev=ymdnext

      tnext=tprev+dtprec
      UTsecnext=UTsectmp
      ymdnext=ymdtmp
    end if


    !INTERPOLATE IN TIME (LINEAR)
    do ix3=1,lx3
      do ix2=1,lx2
        slope(ix2,ix3)=(Qinext(ix2,ix3)-Qiprev(ix2,ix3))/(tnext-tprev)
        Qinow(ix2,ix3)=Qiprev(ix2,ix3)+slope(ix2,ix3)*(t+dt/2d0-tprev)

        slope(ix2,ix3)=(E0inext(ix2,ix3)-E0iprev(ix2,ix3))/(tnext-tprev)
        E0inow(ix2,ix3)=E0iprev(ix2,ix3)+slope(ix2,ix3)*(t+dt/2d0-tprev)
      end do
    end do


    !SOME BASIC DIAGNOSTICS
    if (myid==lid/2) then
      write(*,*) 'tprev,t,tnext:  ',tprev,t+dt/2d0,tnext
      write(*,*) 'Min/max values for Qinow:  ',minval(pack(Qinow,.true.)),maxval(pack(Qinow,.true.))
      write(*,*) 'Min/max values for E0inow:  ',minval(pack(E0inow,.true.)),maxval(pack(E0inow,.true.))
      write(*,*) 'Min/max values for Qiprev:  ',minval(pack(Qiprev,.true.)),maxval(pack(Qiprev,.true.))
      write(*,*) 'Min/max values for E0prev:  ',minval(pack(E0iprev,.true.)),maxval(pack(E0iprev,.true.))
      write(*,*) 'Min/max values for Qinext:  ',minval(pack(Qinext,.true.)),maxval(pack(Qinext,.true.))
      write(*,*) 'Min/max values for E0next:  ',minval(pack(E0inext,.true.)),maxval(pack(E0inext,.true.))
    end if


    !ASSIGN RESULTS OF INTERPOLATION TO OUTPUT VARIABLES
    !background precipitation
    W0pk=3d3
    PhiWpk=1d-5
    do ix3=1,lx3
      do ix2=1,lx2
        W0(ix2,ix3,1)=W0pk 
        PhiWmWm2(ix2,ix3,1)=PhiWpk       
      end do
    end do

    !disturbance precipitation
    W0(:,:,2)=E0inow
    PhiWmWm2(:,:,2)=Qinow
  end subroutine precipBCs_fileinput


  subroutine make_precip_fileinput()


    !INITIALIZE SOME MODULE TIMING VARIABLES
    tprev=0d0; tnext=0d0

  end subroutine make_precip_fileinput

  subroutine clear_precip_fileinput()

    if(allocated(mlonp)) then
      deallocate(mlonp,mlatp,Qp,E0p,mloni,mlati,Qiprev,Qinext,E0iprev,E0inext)
      if (allocated(precdatp)) then
        deallocate(precdatp)
      end if
    end if

  end subroutine clear_precip_fileinput


  subroutine precipBCs(t,x,W0,PhiWmWm2)

    !------------------------------------------------------------
    !-------LOAD UP ARRAYS CONTAINING TOP BOUNDARY CHAR. ENERGY
    !-------AND TOTAL ENERGY FLUX.  GRID VARIABLES INCLUDE
    !-------GHOST CELLS
    !------------------------------------------------------------

    real(wp), intent(in) :: t
    type(curvmesh), intent(in) :: x
    real(wp), dimension(:,:,:), intent(out) :: W0,PhiWmWm2

    real(wp) :: W0pk,PhiWpk,meanW0x3,meanPhiWx3,sigW0x3,sigPhiWx3
    real(wp) :: sigx2,meanx3,sigx3,x30amp,varc,meanx2,x2enve,sigt,meant
    integer :: ix2,ix3,iprec,lx2,lx3,lprec

    
    lx2=size(W0,1)
    lx3=size(W0,2)
    lprec=size(W0,3)    !assumed to be 2 in this subroutine


    !BACKGROUND PRECIPITATION
    W0pk=3d3
!    PhiWpk=1d-5
    PhiWpk=1d-3
    do ix3=1,lx3
      do ix2=1,lx2
        W0(ix2,ix3,1)=W0pk 
        PhiWmWm2(ix2,ix3,1)=PhiWpk       
      end do
    end do


    !PARAMETERS FOR DISTURBANCE PRECIPITATION
    W0pk=100d0
!      sigW0x3=100d3
!      meanW0x3=0d0
    PhiWpk=0d0
!      PhiWpk=1d-5    !successful grad-drift attempts
!      PhiWpk=1d-4    !Swoboda blur testing
!      PhiWpk=0.05d0    !testing of convergent Hall drifts
!      PhiWpk=5d0
!      sigPhiWx3=100d3
!      meanPhiWx3=0d0

!      W0pk=0.3d3
!      sigW0x3=100d3
!      meanW0x3=0d0
!      PhiWpk=2d0
!      sigPhiWx3=100d3
!      meanPhiWx3=0d0

    sigx2=50d3
    meanx2=0d0
!    sigx3=10d3
    sigx3=25d3
    meant=900d0
    sigt=450d0
    x30amp=0d3
    varc=200d0

    !DISTURBANCE ELECTRON PRECIPITATION PATTERN
    do ix3=1,lx3
      do ix2=1,lx2
        W0(ix2,ix3,2)=W0pk
        PhiWmWm2(ix2,ix3,2)=PhiWpk
      end do
    end do

  end subroutine precipBCs

!
!  subroutine precipBCs_GDIKHI(t,x,W0,PhiWmWm2)
!
!    !------------------------------------------------------------
!    !-------LOAD UP ARRAYS CONTAINING TOP BOUNDARY CHAR. ENERGY
!    !-------AND TOTAL ENERGY FLUX.  GRID VARIABLES INCLUDE
!    !-------GHOST CELLS
!    !------------------------------------------------------------
!
!    real(wp), intent(in) :: t
!    type(curvmesh), intent(in) :: x
!    real(wp), dimension(:,:,:), intent(out) :: W0,PhiWmWm2
!
!    real(wp) :: W0pk,PhiWpk,meanW0x3,meanPhiWx3,sigW0x3,sigPhiWx3
!    real(wp) :: sigx2,meanx3,sigx3,x30amp,varc,meanx2,x2enve,sigt,meant
!    integer :: ix2,ix3,iprec,lx2,lx3,lprec
!
!    
!    lx2=size(W0,1)
!    lx3=size(W0,2)
!    lprec=size(W0,3)    !assumed to be 2 in this subroutine
!
!
!    !BACKGROUND PRECIPITATION
!    W0pk=3d3
!    PhiWpk=1d-5
!    do ix3=1,lx3
!      do ix2=1,lx2
!        W0(ix2,ix3,1)=W0pk 
!        PhiWmWm2(ix2,ix3,1)=PhiWpk       
!      end do
!    end do
!
!
!    !PARAMETERS FOR DISTURBANCE PRECIPITATION
!    W0pk=100d0
!!      sigW0x3=100d3
!!      meanW0x3=0d0
!    PhiWpk=0d0
!!      PhiWpk=1d-5    !successful grad-drift attempts
!!      PhiWpk=1d-4    !Swoboda blur testing
!!      PhiWpk=0.05d0    !testing of convergent Hall drifts
!!      PhiWpk=5d0
!!      sigPhiWx3=100d3
!!      meanPhiWx3=0d0
!
!!      W0pk=0.3d3
!!      sigW0x3=100d3
!!      meanW0x3=0d0
!!      PhiWpk=2d0
!!      sigPhiWx3=100d3
!!      meanPhiWx3=0d0
!
!    sigx2=50d3
!    meanx2=0d0
!!    sigx3=10d3
!    sigx3=25d3
!    meant=900d0
!    sigt=450d0
!    x30amp=0d3
!    varc=200d0
!
!    !DISTURBANCE ELECTRON PRECIPITATION PATTERN
!    do ix3=1,lx3
!      do ix2=1,lx2
!        W0(ix2,ix3,2)=W0pk
!        PhiWmWm2(ix2,ix3,2)=PhiWpk
!      end do
!    end do
!
!  end subroutine precipBCs_GDIKHI
!
!
!  subroutine precipBCs_3DPCarc2(t,x,W0,PhiWmWm2)
!
!    !------------------------------------------------------------
!    !-------LOAD UP ARRAYS CONTAINING TOP BOUNDARY CHAR. ENERGY
!    !-------AND TOTAL ENERGY FLUX.  GRID VARIABLES INCLUDE
!    !-------GHOST CELLS
!    !------------------------------------------------------------
!
!    real(wp), intent(in) :: t
!    type(curvmesh), intent(in) :: x
!    real(wp), dimension(:,:,:), intent(out) :: W0,PhiWmWm2
!
!    real(wp) :: W0pk,PhiWpk,meanW0x3,meanPhiWx3,sigW0x3,sigPhiWx3
!    real(wp) :: sigx2,meanx3,sigx3,x30amp,varc,meanx2,x2enve,sigt,meant
!    integer :: ix2,ix3,iprec,lprec
!
!    
!    lprec=size(W0,3)    !assumed to be 2 in this subroutine
!
!
!    !BACKGROUND PRECIPITATION
!    W0pk=5000d0
!    PhiWpk=0.01d0
!    do ix3=1,lx3
!      do ix2=1,lx2
!        W0(ix2,ix3,1)=W0pk
!        PhiWmWm2(ix2,ix3,1)=PhiWpk
!      end do
!    end do
!
!
!    !PARAMETERS FOR DISTURBANCE PRECIPITATION
!    W0pk=100d0
!!      sigW0x3=100d3
!!      meanW0x3=0d0
!    PhiWpk=0.4d0
!    sigx2=50d3
!    meanx2=0d0
!!    sigx3=10d3
!    sigx3=25d3
!    meant=900d0
!    sigt=450d0
!    x30amp=0d3
!    varc=200d0
!
!    !DISTURBANCE ELECTRON PRECIPITATION PATTERN
!    do ix3=1,lx3
!      do ix2=1,lx2
!        meanx3=-varc*meant+varc*t
!
!        W0(ix2,ix3,2)=W0pk
!        PhiWmWm2(ix2,ix3,2)=(PhiWpk*exp(-(x%x3(ix3)-(-sigx3+meanx3+x30amp*cos(2d0*pi/(sigx2/2d0)*x%x2(ix2)) ))**2/2d0/sigx3**2)- &
!                          Phiwpk*exp(-(x%x3(ix3)-(sigx3+meanx3+x30amp*cos(2d0*pi/(sigx2/2d0)*x%x2(ix2)) ))**2/2d0/sigx3**2) )* &
!                            exp(-(x%x2(ix2)-meanx2)**2/2d0/sigx2**2)*exp(-(t-meant)**2/2d0/sigt**2)
!        if (PhiWmWm2(ix2,ix3,2) < 0d0) then
!          PhiWmWm2(ix2,ix3,2)=0d0
!        end if
!      end do
!    end do
!
!  end subroutine precipBCs_3DPCarc2
!
!
!  subroutine precipBCs_original(t,x,W0,PhiWmWm2)
!
!    !------------------------------------------------------------
!    !-------LOAD UP ARRAYS CONTAINING TOP BOUNDARY CHAR. ENERGY
!    !-------AND TOTAL ENERGY FLUX.  GRID VARIABLES INCLUDE
!    !-------GHOST CELLS
!    !------------------------------------------------------------
!
!    real(wp), intent(in) :: t
!    type(curvmesh), intent(in) :: x
!    real(wp), dimension(:,:,:), intent(out) :: W0,PhiWmWm2
!
!    real(wp) :: W0pk,PhiWpk,meanW0x3,meanPhiWx3,sigW0x3,sigPhiWx3
!    real(wp) :: sigx2,meanx3,sigx3,x30amp,varc,meanx2,x2enve,sigt,meant
!    integer :: ix2,ix3,iprec,lprec
!
!    
!!    lx2=size(W0,1)
!!    lx3=size(W0,2)
!    lprec=size(W0,3)    !assumed to be 2 in this subroutine (background and distubance precipitation)
!
!
!    !BACKGROUND PRECIPITATION
!    W0pk=3d3
!    PhiWpk=0.1d0
!    do ix3=1,lx3
!      do ix2=1,lx2
!        W0(ix2,ix3,1)=W0pk 
!        PhiWmWm2(ix2,ix3,1)=PhiWpk       
!      end do
!    end do
!
!
!    !PARAMETERS FOR DISTURBANCE PRECIPITATION
!    W0pk=300d0
!!    if (t<1800) then
!!      PhiWpk=1d-5    !something very small, but nonzero
!!    else
!!      PhiWpk=2d0
!!    end if
!    PhiWpk=1d-5
!    sigx2=0.33d0*(x%x2(lx2)-x%x2(1))
!    meanx2=0.5d0*(x%x2(1)+x%x2(lx2))
!!    sigx3=0.33d0*(x3(lx3)-x3(1))     !needs to be calculated based on full grid
!!    meanx3=0.5d0*(x3(1)+x3(lx3))     !ditto
!    sigx3=0.33d0*(x%x3all(lx3all)-x%x3all(1))    !this requires that all workers have a copy of x3all!!!!
!    meanx3=0.5d0*(x%x3all(1)+x%x3all(lx3all))
!
!
!    !DISTURBANCE ELECTRON PRECIPITATION PATTERN
!    do ix3=1,lx3
!      do ix2=1,lx2
!        W0(ix2,ix3,2)=W0pk
!        PhiWmWm2(ix2,ix3,2)=PhiWpk*exp(-(x%x3(ix3)-meanx3)**2/2d0/sigx3**2)* &
!                            exp(-(x%x2(ix2)-meanx2)**2/2d0/sigx2**2)
!        if (PhiWmWm2(ix2,ix3,2) < 0d0) then
!          PhiWmWm2(ix2,ix3,2)=0d0
!        end if
!      end do
!    end do
!
!
!!    !PARAMETERS FOR DISTURBANCE PRECIPITATION
!!    W0pk=100d0
!!!      sigW0x3=100d3
!!!      meanW0x3=0d0
!!!    PhiWpk=0.4d0     !Perry, et al 2015 RISR arc example
!!      PhiWpk=1d-5    !successful grad-drift attempts
!!!      PhiWpk=1d-4    !Swoboda blur testing
!!!      PhiWpk=0.05d0    !testing of convergent Hall drifts
!!!      PhiWpk=5d0
!!!      sigPhiWx3=100d3
!!!      meanPhiWx3=0d0
!!
!!!      W0pk=0.3d3
!!!      sigW0x3=100d3
!!!      meanW0x3=0d0
!!!      PhiWpk=2d0
!!!      sigPhiWx3=100d3
!!!      meanPhiWx3=0d0
!!
!!    sigx2=50d3
!!    meanx2=0d0
!!!    sigx3=10d3
!!    sigx3=25d3
!!    meant=900d0
!!    sigt=450d0
!!    x30amp=0d3
!!    varc=200d0
!!
!!    !DISTURBANCE ELECTRON PRECIPITATION PATTERN
!!    do ix3=1,lx3
!!      do ix2=1,lx2
!!        meanx3=-varc*meant+varc*t
!!
!!        W0(ix2,ix3,2)=W0pk
!!!        PhiWmWm2(ix2,ix3)=PhiWpk
!!        PhiWmWm2(ix2,ix3,2)=(PhiWpk*exp(-(x3(ix3)-(-sigx3+meanx3+x30amp*cos(2d0*pi/(sigx2/2d0)*x2(ix2)) ))**2/2d0/sigx3**2)- &
!!                          Phiwpk*exp(-(x3(ix3)-(sigx3+meanx3+x30amp*cos(2d0*pi/(sigx2/2d0)*x2(ix2)) ))**2/2d0/sigx3**2) )* &
!!                            exp(-(x2(ix2)-meanx2)**2/2d0/sigx2**2)*exp(-(t-meant)**2/2d0/sigt**2)
!!        if (PhiWmWm2(ix2,ix3,2) < 0d0) then
!!          PhiWmWm2(ix2,ix3,2)=0d0
!!        end if
!!!        PhiWmWm2(ix2,ix3,2)=(PhiWpk*exp(-(x3(ix3)-(-sigx3+meanx3+x30amp*cos(2d0*pi/(sigx2/2d0)*x2(ix2)) ))**2/2d0/sigx3**2) )* &
!!!                              exp(-(x2(ix2)-meanx2)**2/2d0/sigx2**2)*exp(-(t-meant)**2/2d0/sigt**2)
!!      end do
!!    end do
!
!  end subroutine precipBCs_original
!


end module precipBCs_mod

