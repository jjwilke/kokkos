
#These should not be required anymore
#Dependency on kokkoscore/kokkosalgorithms should force the includes
#INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
#INCLUDE_DIRECTORIES(REQUIRED_DURING_INSTALLATION_TESTING ${CMAKE_CURRENT_SOURCE_DIR})
#INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../src )

IF(NOT KOKKOS_HAS_TRILINOS)
  IF(KOKKOS_SEPARATE_LIBS)
    set(TEST_LINK_TARGETS kokkoscore kokkoscontainers)
  ELSE()
    set(TEST_LINK_TARGETS kokkos)
  ENDIF()
ENDIF()


# mfh 03 Nov 2017: The gtest library used here must have a different
# name than that of the gtest library built in KokkosCore.  We can't
# just refer to the library in KokkosCore's tests, because it's
# possible to build only (e.g.,) KokkosAlgorithms tests, without
# building KokkosCore tests.
# jjw 14 Dec 2018: Build a general kokkos gtest that 
# everyone links to and have a single gtest


SET(SOURCES
  TestCuda.cpp
)

SET(LIBRARIES kokkoscore)

IF(Kokkos_ENABLE_OpenMP)
  LIST( APPEND SOURCES
    TestOpenMP.cpp
  )
ENDIF()

IF(Kokkos_ENABLE_Serial)
  LIST( APPEND SOURCES
    TestSerial.cpp
  )
ENDIF()

IF(Kokkos_ENABLE_Pthread)
  LIST( APPEND SOURCES
    TestThreads.cpp
  )
ENDIF()

KOKKOS_ADD_TEST(
  UnitTest
  SOURCES ${SOURCES}
)

