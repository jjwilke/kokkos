#These are tribits wrappers only ever called by Kokkos itself

INCLUDE(CMakeParseArguments)
INCLUDE(CTest)
INCLUDE(GNUInstallDirs)

MESSAGE(STATUS "The project name is: ${PROJECT_NAME}")

#Leave this here for now - but only do for tribits
#This breaks the standalone CMake
IF (KOKKOS_HAS_TRILINOS)
  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_OpenMP)
    SET(${PROJECT_NAME}_ENABLE_OpenMP OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_HPX)
    SET(${PROJECT_NAME}_ENABLE_HPX OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_DEBUG)
    SET(${PROJECT_NAME}_ENABLE_DEBUG OFF)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_CXX11)
    SET(${PROJECT_NAME}_ENABLE_CXX11 ON)
  ENDIF()

  IF(NOT DEFINED ${PROJECT_NAME}_ENABLE_TESTS)
    SET(${PROJECT_NAME}_ENABLE_TESTS OFF)
  ENDIF()

  IF(NOT DEFINED TPL_ENABLE_Pthread)
    SET(TPL_ENABLE_Pthread OFF)
  ENDIF()
ENDIF()

MACRO(KOKKOS_SUBPACKAGE NAME)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_SUBPACKAGE(${NAME})
  else()
    SET(PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    SET(PARENT_PACKAGE_NAME ${PACKAGE_NAME})
    SET(PACKAGE_NAME ${PACKAGE_NAME}${NAME})
    STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
    SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    #ADD_INTERFACE_LIBRARY(PACKAGE_${PACKAGE_NAME})
    #GLOBAL_SET(${PACKAGE_NAME}_LIBS "")
  endif()
ENDMACRO()

MACRO(KOKKOS_SUBPACKAGE_POSTPROCESS)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_SUBPACKAGE_POSTPROCESS()
  endif()
ENDMACRO()

MACRO(KOKKOS_PACKAGE_DECL)

  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_DECL(Kokkos)
  else()
    SET(PACKAGE_NAME Kokkos)
    SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
  endif()

  #SET(TRIBITS_DEPS_DIR "${CMAKE_SOURCE_DIR}/cmake/deps")
  #FILE(GLOB TPLS_FILES "${TRIBITS_DEPS_DIR}/*.cmake")
  #FOREACH(TPL_FILE ${TPLS_FILES})
  #  TRIBITS_PROCESS_TPL_DEP_FILE(${TPL_FILE})
  #ENDFOREACH()

ENDMACRO()


MACRO(KOKKOS_PROCESS_SUBPACKAGES)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PROCESS_SUBPACKAGES()
  else()
    ADD_SUBDIRECTORY(core)
    ADD_SUBDIRECTORY(containers)
    ADD_SUBDIRECTORY(algorithms)
    ADD_SUBDIRECTORY(example)
  endif()
ENDMACRO()

MACRO(KOKKOS_PACKAGE_DEF)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_DEF()
  else()
    #do nothing
  endif()
ENDMACRO()

MACRO(KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL LIBRARY_NAME)
  KOKKOS_LIB_TYPE(${LIBRARY_NAME} INCTYPE)
  TARGET_INCLUDE_DIRECTORIES(${LIBRARY_NAME} ${INCTYPE} $<INSTALL_INTERFACE:${KOKKOS_HEADER_DIR}>)

  INSTALL(
    TARGETS ${LIBRARY_NAME}
    EXPORT ${PROJECT_NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT ${PACKAGE_NAME}
  )

  INSTALL(
    TARGETS ${LIBRARY_NAME}
    EXPORT KokkosTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  VERIFY_EMPTY(KOKKOS_ADD_LIBRARY ${PARSE_UNPARSED_ARGUMENTS})
ENDMACRO()

FUNCTION(KOKKOS_ADD_EXECUTABLE EXE_NAME)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_EXECUTABLE(${EXE_NAME} ${ARGN})
  else()
    CMAKE_PARSE_ARGUMENTS(PARSE
      "TESTONLY"
      ""
      "SOURCES;TESTONLYLIBS"
      ${ARGN})

    ADD_EXECUTABLE(${EXE_NAME} ${PARSE_SOURCES})
    IF (PARSE_TESTONLYLIBS)
      TARGET_LINK_LIBRARIES(${EXE_NAME} PRIVATE ${PARSE_TESTONLYLIBS})
    ENDIF()
    VERIFY_EMPTY(KOKKOS_ADD_EXECUTABLE ${PARSE_UNPARSED_ARGUMENTS})
    #All executables must link to all the kokkos targets
    #This is just private linkage because exe is final
    TARGET_LINK_LIBRARIES(${EXE_NAME} PRIVATE kokkos)
  endif()
ENDFUNCTION()

FUNCTION(KOKKOS_ADD_EXECUTABLE_AND_TEST ROOT_NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_EXECUTABLE_AND_TEST(
    ${ROOT_NAME}
    TESTONLYLIBS kokkos_gtest
    ${ARGN}
    NUM_MPI_PROCS 1
    COMM serial mpi
    FAIL_REGULAR_EXPRESSION "  FAILED  "
  )
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE
    ""
    ""
    "SOURCES;CATEGORIES"
    ${ARGN})
  VERIFY_EMPTY(KOKKOS_ADD_EXECUTABLE_AND_TEST ${PARSE_UNPARSED_ARGUMENTS})
  SET(EXE_NAME ${PACKAGE_NAME}_${ROOT_NAME})
  KOKKOS_ADD_TEST_EXECUTABLE(${EXE_NAME}
    SOURCES ${PARSE_SOURCES}
  )
  KOKKOS_ADD_TEST(NAME ${ROOT_NAME}
    EXE ${EXE_NAME}
    FAIL_REGULAR_EXPRESSION "  FAILED  "
  )
ENDIF()
ENDFUNCTION()

MACRO(KOKKOS_SETUP_BUILD_ENVIRONMENT)
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_compiler_id.cmake)
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_enable_devices.cmake)
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_enable_options.cmake)
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_test_cxx_std.cmake)
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_arch.cmake)
 IF (NOT KOKKOS_HAS_TRILINOS)
  SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${Kokkos_SOURCE_DIR}/cmake/Modules/")
  INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_tpls.cmake)
 ENDIF()
 INCLUDE(${KOKKOS_SRC_PATH}/cmake/kokkos_corner_cases.cmake)
ENDMACRO()

MACRO(KOKKOS_ADD_TEST_EXECUTABLE EXE_NAME)
  CMAKE_PARSE_ARGUMENTS(PARSE
    ""
    ""
    "SOURCES"
    ${ARGN})
  KOKKOS_ADD_EXECUTABLE(${EXE_NAME}
    SOURCES ${PARSE_SOURCES}
    ${PARSE_UNPARSED_ARGUMENTS}
    TESTONLYLIBS kokkos_gtest
  )
ENDMACRO()

MACRO(KOKKOS_PACKAGE_POSTPROCESS)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_PACKAGE_POSTPROCESS()
  endif()
ENDMACRO()

FUNCTION(KOKKOS_SET_LIBRARY_PROPERTIES LIBRARY_NAME)
  CMAKE_PARSE_ARGUMENTS(PARSE
    "PLAIN_STYLE"
    ""
    ""
    ${ARGN})

  IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13")
    #great, this works the "right" way
    TARGET_LINK_OPTIONS(
      ${LIBRARY_NAME} PUBLIC ${KOKKOS_LINK_OPTIONS}
    )
  ELSE()
    IF (PARSE_PLAIN_STYLE)
      TARGET_LINK_LIBRARIES(
        ${LIBRARY_NAME} ${KOKKOS_LINK_OPTIONS}
      )
    ELSE()
      #well, have to do it the wrong way for now
      TARGET_LINK_LIBRARIES(
        ${LIBRARY_NAME} PUBLIC ${KOKKOS_LINK_OPTIONS}
      )
    ENDIF()
  ENDIF()

  TARGET_COMPILE_OPTIONS(
    ${LIBRARY_NAME} PUBLIC
    $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_COMPILE_OPTIONS}>
  )

  TARGET_COMPILE_DEFINITIONS(
    ${LIBRARY_NAME} PUBLIC
    $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_COMPILE_DEFINITIONS}>
  )

  TARGET_LINK_LIBRARIES(
    ${LIBRARY_NAME} PUBLIC ${KOKKOS_LINK_LIBRARIES}
  )

  IF (KOKKOS_ENABLE_CUDA)
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME}
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${KOKKOS_CUDA_OPTIONS}>
    )
    SET(NODEDUP_CUDAFE_OPTIONS)
    FOREACH(OPT ${KOKKOS_CUDAFE_OPTIONS})
      LIST(APPEND NODEDUP_CUDAFE_OPTIONS -Xcudafe ${OPT})
    ENDFOREACH()
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME}
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${NODEDUP_CUDAFE_OPTIONS}>
    )
  ENDIF()

  LIST(LENGTH KOKKOS_XCOMPILER_OPTIONS XOPT_LENGTH)
  IF (XOPT_LENGTH GREATER 1)
    MESSAGE(FATAL_ERROR "CMake deduplication does not allow multiple -Xcompiler flags (${KOKKOS_XCOMPILER_OPTIONS}): will require Kokkos to upgrade to minimum 3.12")
  ENDIF()
  IF(KOKKOS_XCOMPILER_OPTIONS)
    SET(NODEDUP_XCOMPILER_OPTIONS)
    FOREACH(OPT ${KOKKOS_XCOMPILER_OPTIONS})
      #I have to do this for now because we can't guarantee 3.12 support
      #I really should do this with the shell option
      LIST(APPEND NODEDUP_XCOMPILER_OPTIONS -Xcompiler)
      LIST(APPEND NODEDUP_XCOMPILER_OPTIONS ${OPT})
    ENDFOREACH()
    TARGET_COMPILE_OPTIONS(
      ${LIBRARY_NAME}
      PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${NODEDUP_XCOMPILER_OPTIONS}>
    )
  ENDIF()

  IF (KOKKOS_CXX_STANDARD_FEATURE)
    #GREAT! I can do this the right way
    TARGET_COMPILE_FEATURES(${LIBRARY_NAME} PUBLIC ${KOKKOS_CXX_STANDARD_FEATURE})
    IF (NOT KOKKOS_USE_CXX_EXTENSIONS)
      SET_TARGET_PROPERTIES(${LIBRARY_NAME} PROPERTIES CXX_EXTENSIONS OFF)
    ENDIF()
  ELSE()
    #OH, well, no choice but the wrong way
    TARGET_COMPILE_OPTIONS(${LIBRARY_NAME} PUBLIC ${KOKKOS_CXX_STANDARD_FLAG})
  ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOS_INTERNAL_ADD_LIBRARY LIBRARY_NAME)
  CMAKE_PARSE_ARGUMENTS(PARSE
    "STATIC;SHARED"
    ""
    "HEADERS;SOURCES"
    ${ARGN})

  IF(PARSE_HEADERS)
    LIST(REMOVE_DUPLICATES PARSE_HEADERS)
  ENDIF()
  IF(PARSE_SOURCES)
    LIST(REMOVE_DUPLICATES PARSE_SOURCES)
  ENDIF()

  ADD_LIBRARY(
    ${LIBRARY_NAME}
    ${PARSE_HEADERS}
    ${PARSE_SOURCES}
  )

  KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL(${LIBRARY_NAME})

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT ${PACKAGE_NAME}
  )

  #In case we are building in-tree, add an alias name
  #that matches the install Kokkos:: name
  ADD_LIBRARY(Kokkos::${LIBRARY_NAME} ALIAS ${LIBRARY_NAME})
ENDFUNCTION()

FUNCTION(KOKKOS_ADD_LIBRARY LIBRARY_NAME)
  IF (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_LIBRARY(${LIBRARY_NAME} ${ARGN})
    #Stolen from Tribits - it can add prefixes
    SET(TRIBITS_LIBRARY_NAME_PREFIX "${${PROJECT_NAME}_LIBRARY_NAME_PREFIX}")
    SET(TRIBITS_LIBRARY_NAME ${TRIBITS_LIBRARY_NAME_PREFIX}${LIBRARY_NAME})
    #Tribits has way too much techinical debt and baggage to even
    #allow PUBLIC target_compile_options to be used. It forces C++ flags on projects
    #as a giant blob of space-separated strings. We end up with duplicated
    #flags between the flags implicitly forced on Kokkos-dependent and those Kokkos
    #has in its public INTERFACE_COMPILE_OPTIONS.
    #These do NOT get de-deduplicated because Tribits
    #creates flags as a giant monolithic space-separated string
    #Do not set any transitive properties and keep everything working as before
    #KOKKOS_SET_LIBRARY_PROPERTIES(${TRIBITS_LIBRARY_NAME} PLAIN_STYLE)
  ELSE()
    KOKKOS_INTERNAL_ADD_LIBRARY(
      ${LIBRARY_NAME} ${ARGN})
    KOKKOS_SET_LIBRARY_PROPERTIES(${LIBRARY_NAME})
  ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOS_ADD_INTERFACE_LIBRARY NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_LIBRARY(${NAME} ${ARGN})
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE
    ""
    ""
    "HEADERS;SOURCES"
    ${ARGN}
  )

  ADD_LIBRARY(${NAME} INTERFACE)
  KOKKOS_INTERNAL_ADD_LIBRARY_INSTALL(${NAME})

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

  INSTALL(
    FILES  ${PARSE_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT ${PACKAGE_NAME}
  )
ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOS_LIB_INCLUDE_DIRECTORIES TARGET)
  IF(KOKKOS_HAS_TRILINOS)
    #ignore the target, tribits doesn't do anything directly with targets
    TRIBITS_INCLUDE_DIRECTORIES(${ARGN})
  ELSE() #append to a list for later
    KOKKOS_LIB_TYPE(${TARGET} INCTYPE)
    FOREACH(DIR ${ARGN})
      TARGET_INCLUDE_DIRECTORIES(${TARGET} ${INCTYPE} $<BUILD_INTERFACE:${DIR}>)
    ENDFOREACH()
  ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOS_LIB_COMPILE_OPTIONS TARGET)
  IF(KOKKOS_HAS_TRILINOS)
    #don't trust tribits to do this correctly
    KOKKOS_TARGET_COMPILE_OPTIONS(${TARGET} ${ARGN})
  ELSE()
    KOKKOS_LIB_TYPE(${TARGET} INCTYPE)
    KOKKOS_TARGET_COMPILE_OPTIONS(${${PROJECT_NAME}_LIBRARY_NAME_PREFIX}${TARGET} ${INCTYPE} ${ARGN})
  ENDIF()
ENDFUNCTION()

MACRO(KOKKOS_ADD_TEST_DIRECTORIES)
  IF (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_TEST_DIRECTORIES(${ARGN})
  ELSE()
    IF(KOKKOS_ENABLE_TESTS)
      FOREACH(TEST_DIR ${ARGN})
        ADD_SUBDIRECTORY(${TEST_DIR})
      ENDFOREACH()
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(KOKKOS_ADD_EXAMPLE_DIRECTORIES)
  if (KOKKOS_HAS_TRILINOS)
    TRIBITS_ADD_EXAMPLE_DIRECTORIES(${ARGN})
  else()
    IF(KOKKOS_ENABLE_EXAMPLES)
      FOREACH(EXAMPLE_DIR ${ARGN})
        ADD_SUBDIRECTORY(${EXAMPLE_DIR})
      ENDFOREACH()
    ENDIF()
  endif()
ENDMACRO()
