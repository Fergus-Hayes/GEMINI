FC=mpifort
FL=mpifort
MUMPSDIR=/opt/local/lib/
SCALDIR=/opt/local/lib/
BLASDIR=/usr/lib/
INCDIR=/opt/local/include/
#BLACSDIR=$(HOME)/lib/BLACS/

all: 
	$(FC) -I$(INCDIR) -c test_potential2D.f90 -o test_potential2D.o
	$(FL) test_potential2D.o -o test_potential2D -L$(MUMPSDIR) -ldmumps -lmumps_common -L$(SCALDIR) -lscalapack -L$(BLASDIR) -lblas
	$(FC) -I$(INCDIR) -c test_potential3D.f90 -o test_potential3D.o
	$(FL) test_potential3D.o -o test_potential3D -L$(MUMPSDIR) -ldmumps -lmumps_common -L$(SCALDIR) -lscalapack -L$(BLASDIR) -lblas
