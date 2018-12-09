cmake_minimum_required (VERSION 3.11)  # 3.9: MPI::MPI_Fortran, 3.11: Lapack
project(test_gem Fortran)
enable_testing()

if(NOT realbits)
  set(realbits 64)
endif()


if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0")  # quotes are needed!
  cmake_policy(SET CMP0074 NEW)
endif()

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/../cmake/Modules/)


find_package(MPI REQUIRED COMPONENTS Fortran)

add_executable(testmpi test_mpi.f90)
target_link_libraries(testmpi PRIVATE MPI::MPI_Fortran)
add_test(NAME MPIexist COMMAND testmpi)

#---------------
include(${PROJECT_SOURCE_DIR}/../cmake/mumps.cmake)


add_executable(testmumps test_mumps.f90)
target_include_directories(testmumps PRIVATE ${MUMPS_INCLUDE_DIRS})
target_link_libraries(testmumps PRIVATE
                     ${MUMPS_LIBRARIES}
                     MPI::MPI_Fortran)
add_test(NAME MUMPS
  COMMAND ${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${MPIEXEC_MAX_NUMPROCS} ${CMAKE_CURRENT_BINARY_DIR}/testmumps
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})