[![Build Status](https://www.travis-ci.com/mattzett/GEMINI.svg?branch=master)](https://www.travis-ci.com/mattzett/GEMINI)

# GEMINI

The GEMINI model (*G*eospace *E*nvironment *M*odel of *I*on-*N*eutral *I*nteractions) is a three-dimensional ionospheric fluid-electrodynamic model used for various scientific studies including effects of auroras on the terrestrial ionosphere, natural hazard effects on the space environment, and effects of ionospheric fluid instabilities on radio propagation (see references section of this document for details).  
The detailed mathematical formulation of GEMINI is included in `doc/`.
GEMINI uses generalized orthogonal curvilinear coordinates and has been tested with dipole and Cartesian coordinates.

We have prioritized ease of setup/install across a wide variety of computing systems.
Setting up a new simulation and other introductory to advanced task are described in the [Wiki](https://github.com/mattzett/GEMINI/wiki).
Please open a [GitHub Issue](https://github.com/mattzett/gemini/issues) if you experience difficulty building GEMINI.

Generally, the Git `master` branch has the current development version and is the best place to start, while more thoroughly-tested releases happen occasionally.  
Specific commits corresponding to published results will also be noted, where appropriate, in the corresponding journal article.  

## License

GEMINI is distributed under the GNU Affero public license (aGPL) version 3+.


## Suggested hardware

GEMINI can run on hardware ranging from a modest laptop (even a Raspberry Pi, with patience for a very small simulation) to a high-performance computing (HPC) cluster.  
Large 3D simulations (more than 20M grid points) require a cluster environment or a "large" multicore workstation (e.g. 12 or more cores).  
Runtime depends heavily on the grid spacing used, which determines the time step needed to insure stability,  For example we have found that a 20M grid point simulations takes about  4 hours on 72 Xeon E5 cores.  
200M grid point simulations can take up to a week on 256 cores.  
It has generally been found that acceptable performance requires &gt; 1GB memory per core.
A large amount of storage (hundreds of GB to several TB) is needed to store results from large simulations.
One could run large 2D or very small 3D simulations (not exceeding a few million grid points) on a quad-core workstation, but may take quite a while to complete.  


## Quick start
This method is tested on CentOS and Ubuntu.
This test runs a short demo, taking about 2-5 minutes on a typical Mac / Linux laptop, from scratch. 


1. get GEMINI code and install prereqs
   ```sh
   cd ~
   git clone https://github.com/mattzett/gemini
   cd gemini
2. Generate Makefile and auto-download test reference data  
   ```sh
   cd objects

   cmake ..
3. compile
   ```sh
   make -j
   ```
4. run GEMINI demo:
   ```
   ctest --output-on-failure
   ```

If you get errors about libraries not found or it's using the wrong compiler, see the `build_.sh` scripts for examples of how to easily tell CMake to use customer library and compiler locations.

(OPTIONAL HDF5):
as above, adding:

```sh
cmake -DUSEHDF=yes ..
```

### input directory
The example `config.ini` in `initialize/` looks for input grid data in `../simulations`.
If you plan to push back to the repository, please don't edit those example `.ini` file paths, instead use softlinks `ln -s` to point somewhere else if needed.
Note that any `config.ini` you create yourself in `initialize/` will not be included in the repository since that directory is in `.gitignore` (viz. not tracked by git).

#### Build tips

* If the CMake version that ships with your linux or MacOS distribution is too old, use [cmake_setup.sh](https://github.com/scivision/cmake-utils). Note that this script does NOT use `sudo`.

Libraries:

* If you have `sudo` access, try the `./install_prereqs.sh` script
* If need to build libraries from source (e.g. because you don't have `sudo`) try `build_gnu_noMKL.sh` or `build_intel.sh` from the `fortran-libs` repo:
  ```sh
  git clone https://github.com/scivision/fortran-libs ~/flibs-nomkl
  
  cd ~/flibs-nomkl
  
  ./build_gnu_noMKL.sh
  ```


### self-tests
GEMINI has self tests that compare the output from a "known" test problem to a reference output.  So running:
```sh
ctest --output-on-failure
```

1. executes 
   ```sh
   ./gemini initialize/2Dtest/config.ini /tmp/2d
   ```
2. uses GNU Octave (or Matlab) compares with reference output using `tests/compare_all.m`:
   ```matlab
   compare_all(/tmp/2d, '../simulations/2Dtest_files/2Dtest_output')
   ```
   
### OS-specific tips

#### Ubuntu
Tested on Ubuntu 18.04 / 16.04.

If you have sudo (admin) access:
```sh
./install_prereqs.sh
```
Otherwise, ask your IT admin to install the libraries or 
[compile them yourself](https://github.com/scivision/fortran-libs) 
or consider Linuxbrew.


#### CentOS
This is for CentOS 7, using "modules" for more recent libraries.
For the unavailable modules, 
[compile them yourself](https://github.com/scivision/fortran-libs)
```sh
module load git cmake mumps scalapack openmpi lapack metis

module load gcc
export CC=gcc CXX=g++ FC=gfortran
```

Try to compile gemini as above, then 
[build the missing libraries](https://github.com/scivision/fortran-libs).

Example:
```sh
cmake -DSCALAPACK_ROOT=~/flibs-nomkl/scalapack -DMUMPS_ROOT=~/flibs-nomkl/MUMPS ..
```

## To do list

See [TODO.md](./TODO.md).


## Build and run GEMINI

```sh
cd objects
cmake ..
make -j

mpirun -np <number of processors>  ./gemini <input config file> <output directory>
```
for example:
```sh
mpirun -np 4 ./gemini initialize/2Dtest/config.ini ../simulations/2Dtest/
```
Note that the output *base* directory must already exist (`../simulations` in previous example).  The source code consists of about ten module source files encapsulating various functionalities used in the model.  A diagram all of the modules and their function is shown in figure 1; a list of module dependencies can also be found one of the example makefiles included in the repo or in CMakeList.txt.

Two of the log files created are:

* gitrev.log: the Git branch and hash revision at runtime (changed filenames beyond this revision are logged)
* compiler.log: compiler name, version and options used to compile the executable.


![Figure 1](doc/figure1.png)

<!-- ![Figure 2](doc/figure2.png) -->


## Verifying GEMINI build

Assuming you have built by
```sh
cd objects
cmake ..
make
```
* run all self tests:
  ```sh
  ctest --output-on-failure
  ```

Select particular tests using `ctest -R <regexp>`. 

* run 2D tests:
  ```sh
  ctest -R 2D --output-on-failure
  ```
* run 3D tests:
  ```sh
  ctest -R 3D --output-on-failure
  ```

Exclude particular tests using `ctest -E <regexp>`.

* run all except 2D tests:
  ```sh
  ctest -E 2D --output-on-failure
  ```
* run all except 3D tests:
  ```sh
  ctest -E 3D --output-on-failure
  ```

Full debugging and testing is enabled by:
```sh
cmake -DCMAKE_BUILD_TYPE=Debug ..

make

ctest --output-on-failure
```

## Running in two dimensions

The code determines 2D vs. 3D runs by the number of x2 or x3 grid points specified in the `config.ini` input file.  
If the number of x2 grid points is 1, then a 2D run is executed (since message passing in the x3 direction will work normally).  
If the number of x3 grid points is 1, the simulation will swap array dimensions and vector components between the x2 and x3 directions so that MPI parallelization still provides performance benefits.  
The data will be swapped again before output so that the output files are structured normally and the user who is not modifying the source code need not concern themselves with this reordering.

