# warning: PerfTest_CustomReduction.cpp uses
# ../../algorithms/src/Kokkos_Random.hpp
# we'll just allow it to be included, but note
# that in TriBITS KokkosAlgorithms can be disabled...
# DEPRECATED: This should be removed and use transitive deps
INCLUDE_DIRECTORIES("${CMAKE_CURRENT_SOURCE_DIR}/../../algorithms/src")

SET(SOURCES
  PerfTestMain.cpp
  PerfTestGramSchmidt.cpp
  PerfTestHexGrad.cpp
  PerfTest_CustomReduction.cpp
  )

# Per #374, we always want to build this test, but we only want to run
# it as a PERFORMANCE test.  That's why we separate building the test
# from running the test.


KOKKOS_ADD_TEST(
  PerfTest
  SOURCES ${SOURCES}
  CATEGORIES PERFORMANCE
  FORCEBUILD
)

#TRIBITS_ADD_EXECUTABLE(
#  PerfTestExec
#  SOURCES ${SOURCES}
#  COMM serial mpi
#  TESTONLYLIBS kokkos_gtest ${TEST_LINK_TARGETS}
#  )
#
#TRIBITS_ADD_TEST(
#   PerfTest
#  NAME PerfTestExec
#  COMM serial mpi
#  NUM_MPI_PROCS 1
#  CATEGORIES PERFORMANCE
#  FAIL_REGULAR_EXPRESSION "  FAILED  "
#  )

KOKKOS_ADD_TEST(
  PerformanceTest_TaskDAG
  SOURCES test_taskdag.cpp
  CATEGORIES PERFORMANCE
  FORCEBUILD
)

#TRIBITS_ADD_EXECUTABLE(
#  PerformanceTest_TaskDAG
#  SOURCES test_taskdag.cpp
#  COMM serial mpi
#  TESTONLYLIBS ${TEST_LINK_TARGETS}
#  )
#
#TRIBITS_ADD_TEST(
#  PerformanceTest_TaskDAG
#  NAME PerformanceTest_TaskDAG
#  COMM serial mpi
#  NUM_MPI_PROCS 1
#  CATEGORIES PERFORMANCE
#  )

