# CIME/CTSM CMake settings for the container's Conda toolchain.
string(APPEND CXXFLAGS " -std=c++14")
string(APPEND CXX_LIBS " -lstdc++")
string(APPEND FFLAGS " -I/opt/clmu/include")
string(APPEND SLIBS " -L/opt/clmu/lib -lnetcdf -lnetcdff -lpnetcdf -llapack -lblas")
set(MPI_PATH "/opt/clmu")
if (CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
  string(APPEND FFLAGS " -fallow-argument-mismatch -fallow-invalid-boz")
endif()
