cmake_policy(SET CMP0074 NEW)
if(CMAKE_BUILD_TYPE STREQUAL Debug)
  add_compile_options(-g -O0)
else()
  add_compile_options(-g -O3)
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL Intel)
  list(APPEND FFLAGS -traceback -check bounds)
  list(APPEND FFLAGS -qopenmp)  # undefined reference to `omp_get_max_threads'
  
  cmake_policy(VERSION 3.13)
  add_link_options(-parallel) # undefined reference to `__kmpc_begin'
  if(CMAKE_BUILD_TYPE STREQUAL Debug)
    list(APPEND FFLAGS -check all)
    #list(APPEND FFLAGS -debug extended -check all -heap-arrays -fpe0 -fp-stack-check)
    #list(APPEND FFLAGS -check bounds)
  endif()
  
  list(APPEND FFLAGS -warn nounused -traceback -stand f08 
    -diag-disable 5268)

elseif(CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
  # -fdefault-real-8  after literals are fixed to "e" or "wp"
  list(APPEND FFLAGS -march=native -fimplicit-none)
  list(APPEND FFLAGS -Wall -Wpedantic -Wextra)
  if(CMAKE_BUILD_TYPE STREQUAL Debug)
    list(APPEND FFLAGS -fcheck=all)
    # list(APPEND FFLAGS -ffpe-trap=invalid,zero,overflow)#,underflow)
  else()
    list(APPEND FFLAGS -Wno-unused-dummy-argument -Wno-unused-variable -Wno-unused-function)
  endif()
  if(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 6)
     list(APPEND FFLAGS -std=f2008)
  elseif(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 8)
     list(APPEND FFLAGS -std=f2018)
  endif()
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL PGI)

elseif(CMAKE_Fortran_COMPILER_ID STREQUAL Cray)

elseif(CMAKE_Fortran_COMPILER_ID STREQUAL XL)

elseif(CMAKE_Fortran_COMPILER_ID STREQUAL Flang) 
  list(APPEND FFLAGS -Mallocatable=03)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL NAG)
  list(APPEND FFLAGS -u -C=all -f2008)
endif()
