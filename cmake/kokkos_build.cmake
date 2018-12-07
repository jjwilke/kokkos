############################ Detect if submodule ###############################
#
# With thanks to StackOverflow:  
#      http://stackoverflow.com/questions/25199677/how-to-detect-if-current-scope-has-a-parent-in-cmake
#
get_directory_property(HAS_PARENT PARENT_DIRECTORY)
if(HAS_PARENT)
  message(STATUS "Submodule build")
  SET(KOKKOS_HEADER_DIR "include/kokkos")
else()
  message(STATUS "Standalone build")
  SET(KOKKOS_HEADER_DIR "include")
endif()

################################ Handle the actual build #######################

SET(INSTALL_LIB_DIR lib CACHE PATH "Installation directory for libraries")
SET(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
SET(INSTALL_INCLUDE_DIR ${KOKKOS_HEADER_DIR} CACHE PATH
  "Installation directory for header files")
IF(WIN32 AND NOT CYGWIN)
  SET(DEF_INSTALL_CMAKE_DIR cmake)
  SET(STD_INSTALL_CMAKE_DIR cmake)
ELSE()
  SET(DEF_INSTALL_CMAKE_DIR lib/CMake/Kokkos)
  SET(STD_INSTALL_CMAKE_DIR lib/cmake)
ENDIF()

SET(INSTALL_CMAKE_DIR ${DEF_INSTALL_CMAKE_DIR} CACHE PATH
    "Installation directory for CMake files")

# Make relative paths absolute (needed later on)
FOREACH(p LIB BIN INCLUDE CMAKE)
  SET(var INSTALL_${p}_DIR)
  IF(NOT IS_ABSOLUTE "${${var}}")
    SET(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
  ENDIF()
ENDFOREACH()

# set up include-directories
SET (Kokkos_INCLUDE_DIRS
    ${Kokkos_SOURCE_DIR}/core/src
    ${Kokkos_SOURCE_DIR}/containers/src
    ${Kokkos_SOURCE_DIR}/algorithms/src
    ${Kokkos_BINARY_DIR}  # to find KokkosCore_config.h
    ${KOKKOS_INCLUDE_DIRS}
)

# pass include dirs back to parent scope
if(HAS_PARENT)
SET(Kokkos_INCLUDE_DIRS_RET ${Kokkos_INCLUDE_DIRS} PARENT_SCOPE)
else()
SET(Kokkos_INCLUDE_DIRS_RET ${Kokkos_INCLUDE_DIRS})
endif()

IF(KOKKOS_SEPARATE_LIBS)
  # Sources come from makefile-generated kokkos_generated_settings.cmake file
  # Separate libs need to separate the sources
  set_kokkos_srcs(KOKKOS_SRC ${KOKKOS_SRC})

  # kokkoscore
  ADD_LIBRARY(
    kokkoscore
    ${KOKKOS_CORE_SRCS}
  )

  target_include_directories(kokkoscore INTERFACE
      $<INSTALL_INTERFACE:include>
  )

  foreach(inc IN LISTS KOKKOS_TPL_INCLUDE_DIRS)
    target_include_directories(kokkoscore PUBLIC
      $<BUILD_INTERFACE:${inc}>
    )
  endforeach()

  foreach(inc IN LISTS Kokkos_INCLUDE_DIRS)
    target_include_directories(kokkoscore PUBLIC
      $<BUILD_INTERFACE:${inc}>
    )
  endforeach()


  target_compile_options(
    kokkoscore
    PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_CXX_FLAGS}>
  )

  foreach(lib IN LISTS KOKKOS_TPL_LIBRARY_NAMES)
    if ("${lib}" STREQUAL "cuda")
      set(LIB_cuda "-lcuda")
    else()
      find_library(LIB_${lib} ${lib} PATHS ${KOKKOS_TPL_LIBRARY_DIRS})
    endif()
    target_link_libraries(kokkoscore PUBLIC ${LIB_${lib}})
  endforeach()

  target_link_libraries(kokkoscore PUBLIC "${KOKKOS_LINK_FLAGS}")


  # kokkoscontainers
  if (DEFINED KOKKOS_CONTAINERS_SRCS)
    ADD_LIBRARY(
      kokkoscontainers
      ${KOKKOS_CONTAINERS_SRCS}
    )
  endif()

  TARGET_LINK_LIBRARIES(
    kokkoscontainers
    kokkoscore
  )

  # kokkosalgorithms - Build as interface library since no source files.
  ADD_LIBRARY(
    kokkosalgorithms
    INTERFACE
  )

 # No longer needed - target_link should bring in correct includes
 # kokkos_build should only get invoked without Trilions
 # which means "modern" Cmake >=3 is required
 # target_include_directories(
 #   kokkosalgorithms
 #   INTERFACE ${Kokkos_SOURCE_DIR}/algorithms/src
 # )

  TARGET_LINK_LIBRARIES(
    kokkosalgorithms
    INTERFACE kokkoscore
  )

  SET (Kokkos_LIBRARIES_NAMES kokkoscore kokkoscontainers kokkosalgorithms)

  # Install the kokkoscore library
  #normally, we would only do a single install
  #to the standard lib/cmake using a namespaced target
  #however, we want to preserve backward compatibility
  #thus we do with/without namespace to both 
  #standard and kokkos-specific install locations
  install(TARGETS kokkoscore kokkoscontainers kokkosalgorithms
          EXPORT kokkos
          INCLUDES DESTINATION include
          ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
          LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
          RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

  install(EXPORT kokkos
          FILE KokkosTargets.cmake
          NAMESPACE kokkos::
          DESTINATION ${INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosTargets.cmake
          NAMESPACE kokkos::
          DESTINATION ${STD_INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosDeprecatedTargets.cmake
          DESTINATION ${INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosDeprecatedTargets.cmake
          DESTINATION ${STD_INSTALL_CMAKE_DIR})

  export(TARGETS kokkoscore kokkosalgorithms kokkoscontainers
         NAMESPACE kokkos::
         FILE KokkosTargets.cmake)

ELSE()
  # kokkos
  ADD_LIBRARY(
    kokkos
    ${KOKKOS_CORE_SRCS}
    ${KOKKOS_CONTAINERS_SRCS}
  )

  target_compile_options(
    kokkos
    PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_CXX_FLAGS}>
  )

  target_include_directories(kokkos INTERFACE
    $<INSTALL_INTERFACE:include>
  )

  foreach(inc IN LISTS KOKKOS_TPL_INCLUDE_DIRS)
    target_include_directories(kokkos PUBLIC
      $<BUILD_INTERFACE:${inc}>
    )
  endforeach()

  foreach(inc IN LISTS Kokkos_INCLUDE_DIRS)
    target_include_directories(kokkos PUBLIC
      $<BUILD_INTERFACE:${inc}>
    )
  endforeach()

  # Remove: specify as build/install interface above
  # kokkos_build should only get invoked without Trilions
  # which means "modern" Cmake >=3 is required
  # target_include_directories(
  #  kokkos
  #  PUBLIC
  #  ${KOKKOS_TPL_INCLUDE_DIRS}
  #)

  foreach(lib IN LISTS KOKKOS_TPL_LIBRARY_NAMES)
    if ("${lib}" STREQUAL "cuda")
      set(LIB_cuda "-lcuda")
    else()
      find_library(LIB_${lib} ${lib} PATHS ${KOKKOS_TPL_LIBRARY_DIRS})
    endif()
    target_link_libraries(kokkos PUBLIC ${LIB_${lib}})
  endforeach()

  target_link_libraries(kokkos PUBLIC "${KOKKOS_LINK_FLAGS}")

  install(TARGETS kokkos EXPORT kokkos
          INCLUDES DESTINATION include
          ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
          LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
          RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)

  #normally, we would only do a single install
  #to the standard lib/cmake using a namespaced target
  #however, we want to preserve backward compatibility
  #thus we do with/without namespace to both 
  #standard and kokkos-specific install locations
  install(EXPORT kokkos
          FILE KokkosTargets.cmake
          NAMESPACE kokkos::
          DESTINATION ${INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosTargets.cmake
          NAMESPACE kokkos::
          DESTINATION ${STD_INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosDeprecatedTargets.cmake
          DESTINATION ${INSTALL_CMAKE_DIR})
  install(EXPORT kokkos
          FILE KokkosDeprecatedTargets.cmake
          DESTINATION ${STD_INSTALL_CMAKE_DIR})

  export(TARGETS kokkos
         NAMESPACE kokkos::
         FILE KokkosTargets.cmake)

  SET (Kokkos_LIBRARIES_NAMES kokkos)
endif()  # KOKKOS_SEPARATE_LIBS

include(CMakePackageConfigHelpers)
configure_package_config_file(cmake/KokkosConfig.cmake.in
                              "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake"
                              INSTALL_DESTINATION ${INSTALL_CMAKE_DIR})
write_basic_package_version_file("${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfigVersion.cmake"
                                 VERSION "${Kokkos_VERSION_MAJOR}.${Kokkos_VERSION_MINOR}.${Kokkos_VERSION_PATCH}"
                                 COMPATIBILITY SameMajorVersion)

# Install the kokkos headers
INSTALL (DIRECTORY EXPORT kokkos
         ${Kokkos_SOURCE_DIR}/core/src/
         DESTINATION ${KOKKOS_HEADER_DIR}
         FILES_MATCHING PATTERN "*.hpp"
)
INSTALL (DIRECTORY EXPORT kokkos
         ${Kokkos_SOURCE_DIR}/containers/src/
         DESTINATION ${KOKKOS_HEADER_DIR}
         FILES_MATCHING PATTERN "*.hpp"
)
INSTALL (DIRECTORY EXPORT kokkos
         ${Kokkos_SOURCE_DIR}/algorithms/src/
         DESTINATION ${KOKKOS_HEADER_DIR}
         FILES_MATCHING PATTERN "*.hpp"
)

INSTALL (FILES
         ${Kokkos_BINARY_DIR}/KokkosCore_config.h
         DESTINATION ${KOKKOS_HEADER_DIR}
)

# Add all targets to the build-tree export set
# done above already
# all of this is done above
# export(TARGETS ${Kokkos_LIBRARIES_NAMES}
#  FILE "${Kokkos_BINARY_DIR}/KokkosTargets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE Kokkos)

# Create the KokkosConfig.cmake and KokkosConfigVersion files
#file(RELATIVE_PATH REL_INCLUDE_DIR "${INSTALL_CMAKE_DIR}"
#   "${INSTALL_INCLUDE_DIR}")
# ... for the build tree
# This is no longer necessary - build/interface includes now distinguished
#set(CONF_INCLUDE_DIRS "${Kokkos_SOURCE_DIR}" "${Kokkos_BINARY_DIR}")
#configure_file(${Kokkos_SOURCE_DIR}/cmake/KokkosConfig.cmake.in
#  "${Kokkos_BINARY_DIR}/KokkosConfig.cmake" @ONLY)
# ... for the install tree
#set(CONF_INCLUDE_DIRS "\${Kokkos_CMAKE_DIR}/${REL_INCLUDE_DIR}")
#configure_file(${Kokkos_SOURCE_DIR}/cmake/KokkosConfig.cmake.in
#  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake" @ONLY)

# Install the KokkosConfig.cmake and KokkosConfigVersion.cmake
install(FILES
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake"
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfigVersion.cmake"
  DESTINATION "${INSTALL_CMAKE_DIR}")

install(FILES
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfig.cmake"
  "${Kokkos_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/KokkosConfigVersion.cmake"
  DESTINATION "${STD_INSTALL_CMAKE_DIR}")

# build and install pkgconfig file
CONFIGURE_FILE(core/src/kokkos.pc.in kokkos.pc @ONLY)
INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/kokkos.pc DESTINATION lib/pkgconfig)


