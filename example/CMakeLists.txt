

# Subpackage name must match what appears in kokkos/cmake/Dependencies.cmake
#
TRIBITS_SUBPACKAGE(Example)

add_library(example_common INTERFACE)
target_include_directories(example_common INTERFACE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/common>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/fixture>
)

function (Kokkos_ADD_EXAMPLE_EXECUTABLE name sourcelist)
  IF(NOT KOKKOS_HAS_TRILINOS)
    IF(KOKKOS_SEPARATE_LIBS)
      set(EXAMPLE_LINK_TARGETS kokkoscore kokkoscontainers)
    ELSE()
      set(EXAMPLE_LINK_TARGETS kokkos)
    ENDIF()
  ENDIF()

  TRIBITS_ADD_EXECUTABLE(
    ${name}
    SOURCES ${sourcelist}
    COMM serial mpi
    TESTONLYLIBS ${EXAMPLE_LINK_TARGETS}
    NOEXEPREFIX TRUE
  )

  target_INCLUDE_DIRECTORIES(${name} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
  target_INCLUDE_DIRECTORIES(${name} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
  target_link_libraries(${name} LINK_PUBLIC example_common)
endfunction(Kokkos_ADD_EXAMPLE_EXECUTABLE)

function (Kokkos_ADD_EXAMPLE_EXECUTABLE_AND_TEST name sourcelist)
  IF(NOT KOKKOS_HAS_TRILINOS)
    IF(KOKKOS_SEPARATE_LIBS)
      set(EXAMPLE_LINK_TARGETS kokkoscore kokkoscontainers)
    ELSE()
      set(EXAMPLE_LINK_TARGETS kokkos)
    ENDIF()
  ENDIF()

  TRIBITS_ADD_EXECUTABLE_AND_TEST(
    ${name}
    SOURCES ${sourcelist}
    COMM serial mpi
    TESTONLYLIBS ${EXAMPLE_LINK_TARGETS}
    NOEXEPREFIX TRUE
  )

  target_INCLUDE_DIRECTORIES(${name} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
  target_INCLUDE_DIRECTORIES(${name} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
  target_link_libraries(${name} LINK_PUBLIC example_common)
endfunction(Kokkos_ADD_EXAMPLE_EXECUTABLE_AND_TEST)



TRIBITS_ADD_EXAMPLE_DIRECTORIES(query_device)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(fixture)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(feint)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(fenl)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(multi_fem)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(md_skeleton)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(global_2_local_ids)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(grow_array)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(sort_array)
if(NOT Kokkos_ENABLE_Cuda)
TRIBITS_ADD_EXAMPLE_DIRECTORIES(tutorial)
endif()
TRIBITS_SUBPACKAGE_POSTPROCESS()

