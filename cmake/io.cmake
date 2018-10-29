# --- HDF5
function(iofun USEHDF5)
  add_library(io io/io.f90 io/expanduser.f90)
  target_link_libraries(io PRIVATE const mpimod grid calculus)
  target_compile_definitions(io PRIVATE TRACE=${TRACE})
  target_include_directories(io PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/numerical)
  target_compile_options(io PRIVATE ${FFLAGS})

  if(USEHDF5)
    find_package(HDF5 REQUIRED COMPONENTS Fortran Fortran_HL)

    add_library(hdf5oo vendor/hdf5/hdf5_interface.f90)
    target_include_directories(hdf5oo PRIVATE ${HDF5_INCLUDE_DIRS} ${HDF5_Fortran_INCLUDE_DIRS})
    target_link_libraries(hdf5oo PRIVATE ${HDF5_Fortran_LIBRARIES} ${HDF5_Fortran_HL_LIBRARIES})

    target_sources(io PRIVATE io/writeHDF5.f90)
    target_link_libraries(io PRIVATE hdf5oo)
  else()
    target_sources(io PRIVATE io/writeraw.f90)
  endif()
endfunction(iofun)
