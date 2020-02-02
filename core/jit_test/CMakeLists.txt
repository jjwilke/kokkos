#
# Add test-only library for gtest to be reused by all the subpackages
#

ADD_COMPILE_OPTIONS(-fjit)
LINK_LIBRARIES( -fjit Kokkos::kokkos)
ADD_EXECUTABLE(jit_fail jit_fail.cpp)
ADD_EXECUTABLE(jit_pass jit_pass.cpp)

