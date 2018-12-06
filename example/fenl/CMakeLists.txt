

SET(SOURCES "")

FILE( GLOB SOURCES *.cpp )

LIST( APPEND SOURCES ../fixture/BoxElemPart.cpp )

#Must be quoted to propagate list correctly
Kokkos_ADD_EXAMPLE_EXECUTABLE(fenl "${SOURCES}")


