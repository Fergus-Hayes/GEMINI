add_executable(test_interp1 testinterp1.f90)
target_link_libraries(test_interp1 interp)


add_executable(test_interp2 testinterp2.f90)
target_link_libraries(test_interp2 interp)

add_test(NAME Interp1D COMMAND test_interp1) 

add_test(NAME Interp2D COMMAND test_interp2)
set_tests_properties(Interp2D PROPERTIES
                     TIMEOUT 5
                     FIXTURES_SETUP GemInterp) 


find_package(Octave)
if (OCTAVE_MAJOR_VERSION GREATER_EQUAL 4)

add_test(NAME OctaveInterp 
         COMMAND octave-cli -q --eval "testinterp('${CMAKE_CURRENT_BINARY_DIR}/output2D.dat')"
         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
         

set_tests_properties(OctaveInterp PROPERTIES
                     TIMEOUT 5
                     FIXTURES_REQUIRED GemInterp)

endif()