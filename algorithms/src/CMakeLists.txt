
TRIBITS_CONFIGURE_FILE(${PACKAGE_NAME}_config.h)

KOKKOS_SET_TRIBITS_INCLUDES(
 ALGO_INCLUDES 
 ${CMAKE_CURRENT_BINARY_DIR}
 ${CMAKE_CURRENT_SOURCE_DIR}
)

#-----------------------------------------------------------------------------

FILE(GLOB HEADERS *.hpp)
FILE(GLOB SOURCES *.cpp)
LIST(APPEND HEADERS ${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}_config.h)

#-----------------------------------------------------------------------------



TRIBITS_ADD_LIBRARY(
    kokkosalgorithms
    HEADERS ${HEADERS}
    SOURCES ${SOURCES}
    DEPLIBS
)

KOKKOS_TARGET_INCLUDES(kokkosalgorithms ${ALGO_INCLUDES})
  
