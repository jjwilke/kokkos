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

cmake_minimum_required(VERSION 3.1)
project(Example CXX C Fortran)

# The binary dir here is not necessary if copy is copied into your project
# and is a nested subdirectory
add_subdirectory(${Example_SOURCE_DIR}/../.. ${Example_BINARY_DIR}/kokkos)

add_executable(example cmake_example.cpp foo.f)
target_link_libraries(example kokkos)
