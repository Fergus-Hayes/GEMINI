# --- HDF5
function(iofun USEHDF5)
  add_library(io io/io.f90 io/expanduser.f90)
  target_link_libraries(io PRIVATE const mpimod grid calculus)
  target_compile_definitions(io PRIVATE TRACE=${TRACE})
  target_compile_options(io PRIVATE ${FFLAGS})

  if(USEHDF5)
    find_package(HDF5 REQUIRED COMPONENTS Fortran Fortran_HL)

    include(FetchContent)

    FetchContent_Declare(oohdf5
      GIT_REPOSITORY https://github.com/scivision/oo_hdf5_fortran.git
      GIT_TAG 25c27b6
    )


    FetchContent_GetProperties(oohdf5)

    if(NOT oohdf5_POPULATED)
      FetchContent_Populate(oohdf5)
      # builds under bin/_deps/oodfh5/
      add_subdirectory(${oohdf5_SOURCE_DIR} ${oohdf5_BINARY_DIR})
    endif()

    target_sources(io PRIVATE io/writeHDF5.f90 io/readHDF5.f90)
    target_link_libraries(io PRIVATE hdf5oo)
    target_include_directories(io PRIVATE ${oohdf5_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR}/numerical)
  else()
    target_sources(io PRIVATE io/writeraw.f90 io/readraw.f90)
  endif()
endfunction(iofun)
