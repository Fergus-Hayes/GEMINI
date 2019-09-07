FC=mpif90
FL=mpif90
MUMPSDIR=$(HOME)/lib/MUMPS_4.10.0/
BLACSDIR=$(HOME)/lib/BLACS/
SCALDIR=$(HOME)/lib/scalapack-2.0.2

all: 
#	$(FC) -O  -DALLOW_NON_INIT -nofor_main -I$(MUMPSDIR)/libseq -I. -I$(MUMPSDIR)include -c test_potential2D.f90 -o test_potential2D.o
#	$(FL) -o test_potential2D -O test_potential2D.o  $(MUMPSDIR)lib/libdmumps.a $(MUMPSDIR)lib/libmumps_common.a  -L$(MUMPSDIR)PORD/lib/ -lpord  -L$(MUMPSDIR)libseq -lmpiseq -L/local/BLAS -lblas -lpthread
	$(FC) -O  -DALLOW_NON_INIT -I/usr/lib/openmpi/include -I$(MUMPSDIR) -I$(MUMPSDIR)/include -c test_potential2D.f90 -o test_potential2D.o
	$(FL) -o test_potential2D -O test_potential2D.o  $(MUMPSDIR)/lib/libdmumps.a $(MUMPSDIR)/lib/libmumps_common.a  -L$(MUMPSDIR)/PORD/lib/ -lpord $(SCALDIR)/libscalapack.a $(BLACSDIR)/LIB/blacs_MPI-LINUX-0.a $(BLACSDIR)/LIB/blacsF77init_MPI-LINUX-0.a $(BLACSDIR)/LIB/blacs_MPI-LINUX-0.a  -L/usr/local/lib/ -lmpi -lutil -ldl -lpthread -lgfortran -L/local/BLAS -lblas -lpthread
	$(FC) -O  -DALLOW_NON_INIT -I/usr/lib/openmpi/include -I$(MUMPSDIR) -I$(MUMPSDIR)/include -c test_potential3D.f90 -o test_potential3D.o
	$(FL) -o test_potential3D -O test_potential3D.o $(MUMPSDIR)/lib/libdmumps.a $(MUMPSDIR)/lib/libmumps_common.a  -L$(MUMPSDIR)/PORD/lib/ -lpord $(SCALDIR)/libscalapack.a $(BLACSDIR)/LIB/blacs_MPI-LINUX-0.a $(BLACSDIR)/LIB/blacsF77init_MPI-LINUX-0.a $(BLACSDIR)/LIB/blacs_MPI-LINUX-0.a  -L/usr/local/lib/ -lmpi -lutil -ldl -lpthread -lgfortran -L/local/BLAS -lblas -lpthread 
