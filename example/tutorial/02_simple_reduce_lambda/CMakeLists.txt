
IF (Kokkos_ENABLE_CXX11)
  # This is a tutorial, not a test, so we don't ask CTest to run it.
  Kokkos_ADD_EXAMPLE_EXECUTABLE(
    tutorial_02_simple_reduce_lambda
    simple_reduce_lambda.cpp
  )
ENDIF ()

