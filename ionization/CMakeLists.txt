add_library(fang fang.f90)
target_link_libraries(fang PRIVATE const)
target_include_directories(fang INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)
set_target_properties(fang PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

add_library(fang_run fang_run.f90)
target_link_libraries(fang_run PRIVATE fang msis const)


add_executable(test_fang test_fang.f90)
target_link_libraries(test_fang PRIVATE fang_run const)

if(PythonOK)
add_test(NAME FangIonize
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/test_fang.py $<TARGET_FILE:test_fang>)
set_tests_properties(FangIonize PROPERTIES TIMEOUT 10)
endif(PythonOK)

if(glow)
  include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/glow.cmake)

  add_library(ionization ionization.f90 glow_run.F90)
  target_link_libraries(ionization PUBLIC glow::glow)
else()
  add_library(ionization ionization.f90 glow_dummy.f90)
endif(glow)
target_link_libraries(ionization PRIVATE const neutral grid mesh timeutils fang mpimod MPI::MPI_Fortran)
target_include_directories(ionization INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)
set_target_properties(ionization PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)

add_library(precipBCs boundary_conditions/precipBCs_mod.f90)
target_link_libraries(precipBCs PRIVATE mpimod reader const grid mesh interp timeutils MPI::MPI_Fortran)
target_include_directories(precipBCs INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)
set_target_properties(precipBCs PROPERTIES
  Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)