
# This is a tutorial, not a test, so we don't ask CTest to run it.
Kokkos_ADD_EXAMPLE_EXECUTABLE(
  tutorial_advancedviews_04_dualviews
  dual_view.cpp
  serial mpi
)

