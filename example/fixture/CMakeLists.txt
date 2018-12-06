
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
#INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/../common)

SET(SOURCES_TEST Main.cpp TestFixture.cpp BoxElemPart.cpp )

# Automatically picks up 'kokkosexample_fixture'
# Sources must be quoted here
Kokkos_ADD_EXAMPLE_EXECUTABLE_AND_TEST(TestFixture "${SOURCES_TEST}")

