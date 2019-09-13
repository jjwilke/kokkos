# Kokkos requires CMake version 3.10 (3.12 is better) or higher.
#
# All the flags, etc. required to build using the Kokkos library are
# transitively added to targets which depend on the library.
#
# The CMake variables CMAKE_CXX_STANDARD and CMAKE_CXX_EXTENSIONS are
# respected.  We recommend that you set CMAKE_CXX_EXTENSIONS to OFF.
# Otherwise, CMake defaults to using extensions for the C++ standard, and the
# GNU extensions (-std=gnu++11) will be used for compilers that support it
# instead of standard C++11 (-std=c++11).
#
# A bunch of build options are added as variables (all starting with Kokkos_)
# to the build.  See BUILD.md or check them out using ccmake or the CMake GUI.
#
# Building this example:
#   1. Create a build directory.
#   2. cd /path/to/build/directory
#   3. cmake /path/to/example
#   4. make

cmake_minimum_required(VERSION 3.12)
project(Example CXX C Fortran)

# This may require you to have -DKokkos_DIR or -DKokkos_ROOT set correctly
find_package(Kokkos)

add_executable(example cmake_example.cpp foo.f)
target_link_libraries(example Kokkos::kokkos)
