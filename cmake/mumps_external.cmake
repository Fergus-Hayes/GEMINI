include(FetchContent)

FetchContent_Declare(MUMPS
  GIT_REPOSITORY https://github.com/scivision/mumps.git
  GIT_TAG master
  CMAKE_ARGS "-Darith=${arith}" "-Dparallel=true" "-Dmetis=${metis}" "-Dscotch=${scotch}" "-Dopenmp=false"
)

FetchContent_MakeAvailable(MUMPS)