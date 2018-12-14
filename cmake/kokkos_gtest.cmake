#just use our gtest - why point at anything else
SET(GTEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/tpls/gtest)

#always export kokkos_gtest for others to use
#even if testing is not activated directly for kokkos
TRIBITS_ADD_LIBRARY(
  kokkos_gtest
  SOURCES ${GTEST_SOURCE_DIR}/gtest/gtest-all.cc
  HEADERS ${GTEST_SOURCE_DIR}/gtest/gtest.h
  HEADERS_INSTALL_SUBDIR ${KOKKOS_HEADER_DIR}/gtest
)

TARGET_INCLUDE_DIRECTORIES(kokkos_gtest PUBLIC
  $<INSTALL_INTERFACE:${KOKKOS_HEADER_DIR}>
  $<BUILD_INTERFACE:${GTEST_SOURCE_DIR}>
)
TARGET_COMPILE_DEFINITIONS(kokkos_gtest PUBLIC "GTEST_HAS_PTHREAD=0")
