
# This is a tutorial, not a test, so we don't ask CTest to run it.
IF(Kokkos_ENABLE_CXX11)

Kokkos_ADD_EXAMPLE_EXECUTABLE(
  tutorial_hierarchicalparallelism_03_vectorization
  vectorization.cpp
)

ENDIF()

