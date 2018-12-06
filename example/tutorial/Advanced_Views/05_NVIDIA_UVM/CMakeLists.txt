
IF (Kokkos_ENABLE_Cuda_UVM)
  # This is a tutorial, not a test, so we don't ask CTest to run it.
  Kokkos_ADD_EXAMPLE_EXECUTABLE(
    uvm_example.cpp
  )
  target_link_libraries(tutorial_advancedviews_05_nvidia_uvm
    kokkoscontainers kokkoscore)
ENDIF ()
