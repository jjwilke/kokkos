
# This is a tutorial, not a test, so we don't ask CTest to run it.
Kokkos_ADD_EXAMPLE_EXECUTABLE(
  tutorial_hierarchicalparallelism_01_thread_teams
  thread_teams.cpp
  serial mpi
)

