cmake_minimum_required(VERSION 3.11)   # 3.9: MPI::MPI_Fortran  3.11 for FindLapack bug
project(gemini3d Fortran C)  # MUST include C language for Intel / MKL to work
enable_testing()

if(NOT realbits)
  set(realbits 64)
endif()

option(USEMKL "Use Intel MKL with your compiler")

if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0")  # quotes are needed!
  cmake_policy(SET CMP0074 NEW)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/Modules/)

include(${PROJECT_SOURCE_DIR}/cmake/compilers.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/libraries.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/mumps.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/utils.cmake)

add_subdirectory(vendor/msis00)

# --- Build Gemini
add_subdirectory(numerical)

add_library(io io/io.f90 io/expanduser.f90)
target_link_libraries(io PRIVATE const mpimod grid calculus)
target_include_directories(io PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(temporal temporal/temporal.f90)
target_link_libraries(temporal PRIVATE const mpimod grid MPI::MPI_Fortran)
target_include_directories(temporal PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(neutral neutral/neutral.f90)
target_link_libraries(neutral PUBLIC interp io msis temporal MPI::MPI_Fortran)
target_include_directories(neutral PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(ionization ionization/ionization.f90)
target_link_libraries(ionization PRIVATE neutral)
target_include_directories(ionization PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(collision collisions/collisions.f90)
target_link_libraries(collision PRIVATE const)
target_include_directories(collision PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(sources sources/sources.f90)
target_link_libraries(sources PRIVATE collision grid calculus)
target_include_directories(sources PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

# --- MUMPS stuff
add_library(potential_mumps numerical/potential/potential_mumps.F90)
target_link_libraries(potential_mumps PRIVATE const grid calculus
       ${MUMPS_LIBRARIES}
       MPI::MPI_Fortran)
target_compile_definitions(potential_mumps PRIVATE REALBITS=${realbits})
target_include_directories(potential_mumps PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical
${MUMPS_INCLUDE_DIRS})

add_library(potential_comm_mumps numerical/potential/potential_comm_mumps.f90)
target_link_libraries(potential_comm_mumps PRIVATE potential_mumps potentialBCs collision calculus grid const)
target_include_directories(potential_comm_mumps PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(potentialBCs numerical/potential/boundary_conditions/potentialBCs_mumps.f90)
target_link_libraries(potentialBCs PRIVATE temporal grid calculus interp io const
    ${MUMPS_LIBRARIES}
#    ${BLAS_LIBRARIES}
    MPI::MPI_Fortran)
target_include_directories(potentialBCs PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical
    ${MUMPS_INCLUDE_DIRS})

# --- other libs
add_library(precipBCs ionization/boundary_conditions/precipBCs_mod.f90)
target_link_libraries(precipBCs PRIVATE const grid io interp temporal)
target_include_directories(precipBCs PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

add_library(multifluid multifluid/multifluid.f90)
target_link_libraries(multifluid PRIVATE precipBCs mpimod grid ionization sources advec diffusion)
target_include_directories(multifluid PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)


# --- Main GEMINI executable
add_executable(gemini gemini.f90)
target_link_libraries(gemini PRIVATE mpimod io neutral precipBCs
  temporal multifluid
  potentialBCs potential_comm_mumps const
  ${MUMPS_LIBRARIES})
#  MPI::MPI_Fortran)
target_include_directories(gemini PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical
    ${MUMPS_INCLUDE_DIRS})

#--------magnetic field calculation executable---------------
add_executable(magcalc magcalc.f90)
target_link_libraries(magcalc PRIVATE mpimod const grid io temporal)
target_include_directories(magcalc PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)

# --- self-tests
include(${PROJECT_SOURCE_DIR}/cmake/test2d.cmake)
include(${PROJECT_SOURCE_DIR}/cmake/test3d.cmake)