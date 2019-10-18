################################### FUNCTIONS ##################################
# List of functions
#   kokkos_option

# Validate options are given with correct case and define an internal
# upper-case version for use within 

# 
#
# @FUNCTION: kokkos_deprecated_list
#
# Function that checks if a deprecated list option like Kokkos_ARCH was given.
# This prints an error and prevents configure from completing.
# It attempts to print a helpful message about updating the options for the new CMake.
# Kokkos_${SUFFIX} is the name of the option (like Kokkos_ARCH) being checked.
# Kokkos_${PREFIX}_X is the name of new option to be defined from a list X,Y,Z,...
FUNCTION(kokkos_deprecated_list SUFFIX PREFIX)
  SET(CAMEL_NAME Kokkos_${SUFFIX})
  STRING(TOUPPER ${CAMEL_NAME} UC_NAME)

  #I don't love doing it this way but better to be safe
  FOREACH(opt ${KOKKOS_GIVEN_VARIABLES})
    STRING(TOUPPER ${opt} OPT_UC)
    IF ("${OPT_UC}" STREQUAL "${UC_NAME}")
      STRING(REPLACE "," ";" optlist "${${opt}}")
      SET(ERROR_MSG "Given deprecated option list ${opt}. This must now be given as separate -D options, which assuming you spelled options correctly would be:")
      FOREACH(entry ${optlist})
        STRING(TOUPPER ${entry} ENTRY_UC)
        STRING(APPEND ERROR_MSG "\n  -DKokkos_${PREFIX}_${ENTRY_UC}=ON")
      ENDFOREACH()
      STRING(APPEND ERROR_MSG "\nRemove CMakeCache.txt and re-run. For a list of valid options, refer to BUILD.md or even look at CMakeCache.txt (before deleting it).")
      MESSAGE(SEND_ERROR ${ERROR_MSG})
    ENDIF()
  ENDFOREACH()
ENDFUNCTION()

FUNCTION(kokkos_option CAMEL_SUFFIX DEFAULT TYPE DOCSTRING)
  SET(CAMEL_NAME Kokkos_${CAMEL_SUFFIX})
  STRING(TOUPPER ${CAMEL_NAME} UC_NAME)

  # Make sure this appears in the cache with the appropriate DOCSTRING
  SET(${CAMEL_NAME} ${DEFAULT} CACHE ${TYPE} ${DOCSTRING})

  #I don't love doing it this way because it's N^2 in number options, but cest la vie
  FOREACH(opt ${KOKKOS_GIVEN_VARIABLES})
    STRING(TOUPPER ${opt} OPT_UC)
    IF ("${OPT_UC}" STREQUAL "${UC_NAME}")
      IF (NOT "${opt}" STREQUAL "${CAMEL_NAME}")
        MESSAGE(FATAL_ERROR "Matching option found for ${CAMEL_NAME} with the wrong case ${opt}. Please delete your CMakeCache.txt and change option to -D${CAMEL_NAME}=${${opt}}. This is now enforced to avoid hard-to-debug CMake cache inconsistencies.")
      ENDIF()
    ENDIF()
  ENDFOREACH()

  #okay, great, we passed the validation test - use the default
  IF (DEFINED ${CAMEL_NAME})
    SET(${UC_NAME} ${${CAMEL_NAME}} PARENT_SCOPE)
  ELSE()
    SET(${UC_NAME} ${DEFAULT} PARENT_SCOPE)
  ENDIF()

ENDFUNCTION()

FUNCTION(kokkos_append_config_line LINE)
  GLOBAL_APPEND(KOKKOS_TPL_EXPORTS "${LINE}")
ENDFUNCTION()

MACRO(kokkos_export_cmake_tpl NAME)
  IF (DEFINED ${NAME}_DIR)
    KOKKOS_APPEND_CONFIG_LINE("IF(NOT DEFINED ${NAME}_DIR)")
    KOKKOS_APPEND_CONFIG_LINE("  SET(${NAME}_DIR  ${${NAME}_DIR})")
    KOKKOS_APPEND_CONFIG_LINE("ENDIF()")
  ENDIF()

  IF (DEFINED ${NAME}_ROOT)
    KOKKOS_APPEND_CONFIG_LINE("IF(NOT DEFINED ${NAME}_ROOT)")
    KOKKOS_APPEND_CONFIG_LINE("  SET(${NAME}_ROOT  ${${NAME}_ROOT})")
    KOKKOS_APPEND_CONFIG_LINE("ENDIF()")
  ENDIF()
  KOKKOS_APPEND_CONFIG_LINE("FIND_DEPENDENCY(${NAME})")
ENDMACRO()

MACRO(kokkos_export_imported_tpl NAME)
  IF (NOT KOKKOS_HAS_TRILINOS)
    GET_TARGET_PROPERTY(LIB_TYPE ${NAME} TYPE)
    IF (${LIB_TYPE} STREQUAL "INTERFACE_LIBRARY")
      # This is not an imported target
      # This an interface library that we created
      INSTALL(
        TARGETS ${NAME}
        EXPORT KokkosTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      )
    ELSE()
      #make sure this also gets "exported" in the config file
      KOKKOS_APPEND_CONFIG_LINE("ADD_LIBRARY(${NAME} UNKNOWN IMPORTED)")
      KOKKOS_APPEND_CONFIG_LINE("SET_TARGET_PROPERTIES(${NAME} PROPERTIES")
      
      GET_TARGET_PROPERTY(TPL_LIBRARY ${NAME} IMPORTED_LOCATION)
      IF(TPL_LIBRARY)
        KOKKOS_APPEND_CONFIG_LINE("IMPORTED_LOCATION ${TPL_LIBRARY}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_INCLUDES ${NAME} INTERFACE_INCLUDE_DIRECTORIES)
      IF(TPL_INCLUDES)
        KOKKOS_APPEND_CONFIG_LINE("INTERFACE_INCLUDE_DIRECTORIES ${TPL_INCLUDES}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_COMPILE_OPTIONS ${NAME} INTERFACE_COMPILE_OPTIONS)
      IF(TPL_COMPILE_OPTIONS)
        KOKKOS_APPEND_CONFIG_LINE("INTERFACE_COMPILE_OPTIONS ${TPL_COMPILE_OPTIONS}")
      ENDIF()

      SET(TPL_LINK_OPTIONS)
      IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.13.0")
        GET_TARGET_PROPERTY(TPL_LINK_OPTIONS ${NAME} INTERFACE_LINK_OPTIONS)
      ENDIF()
      IF(TPL_LINK_OPTIONS)
        KOKKOS_APPEND_CONFIG_LINE("INTERFACE_LINK_OPTIONS ${TPL_LINK_OPTIONS}")
      ENDIF()

      GET_TARGET_PROPERTY(TPL_LINK_LIBRARIES  ${NAME} INTERFACE_LINK_LIBRARIES)
      IF(TPL_LINK_LIBRARIES)
        KOKKOS_APPEND_CONFIG_LINE("INTERFACE_LINK_LIBRARIES ${TPL_LINK_LIBRARIES}")
      ENDIF()
      KOKKOS_APPEND_CONFIG_LINE(")")
    ENDIF()
  ENDIF()
ENDMACRO()


MACRO(kokkos_import_tpl NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "NO_EXPORT;INTERFACE"
   ""
   ""
   ${ARGN})
  IF (TPL_INTERFACE)
    SET(TPL_IMPORTED_NAME ${NAME})
  ELSE()
    SET(TPL_IMPORTED_NAME Kokkos::${NAME})
  ENDIF()

  IF(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.12.0") 
    CMAKE_POLICY(SET CMP0074 NEW)
  ENDIF()

  IF (KOKKOS_ENABLE_${NAME})
    #Tack on a TPL here to make sure we avoid using anyone else's find
    FIND_PACKAGE(TPL${NAME} REQUIRED MODULE)
    IF(NOT TARGET ${TPL_IMPORTED_NAME})
      MESSAGE(FATAL_ERROR "Find module succeeded for ${NAME}, but did not produce valid target ${TPL_IMPORTED_NAME}")
    ENDIF()
    IF(NOT TPL_NO_EXPORT)
      KOKKOS_EXPORT_IMPORTED_TPL(${TPL_IMPORTED_NAME})
    ENDIF()
  ENDIF()
ENDMACRO(kokkos_import_tpl)

MACRO(kokkos_import_cmake_tpl MODULE_NAME)
  kokkos_import_tpl(${MODULE_NAME} ${ARGN} NO_EXPORT)
  CMAKE_PARSE_ARGUMENTS(TPL
   "NO_EXPORT"
   "OPTION_NAME"
   ""
   ${ARGN})

  IF (NOT TPL_OPTION_NAME)
    SET(TPL_OPTION_NAME ${MODULE_NAME})
  ENDIF()

  IF (NOT TPL_NO_EXPORT)
    KOKKOS_EXPORT_CMAKE_TPL(${MODULE_NAME})
  ENDIF()
ENDMACRO()

MACRO(kokkos_create_imported_tpl NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "INTERFACE"
   "LIBRARY"
   "LINK_LIBRARIES;INCLUDES;COMPILE_OPTIONS;LINK_OPTIONS"
   ${ARGN})


  IF (KOKKOS_HAS_TRILINOS)
    #TODO: we need to set a bunch of cache variables here
  ELSEIF (TPL_INTERFACE)
    ADD_LIBRARY(${NAME} INTERFACE)
    #Give this an importy-looking name
    ADD_LIBRARY(Kokkos::${NAME} ALIAS ${NAME})
    IF (TPL_LIBRARY)
      MESSAGE(SEND_ERROR "TPL Interface library ${NAME} should not have an IMPORTED_LOCATION")
    ENDIF()
    #Things have to go in quoted in case we have multiple list entries
    IF(TPL_LINK_LIBRARIES)
      TARGET_LINK_LIBRARIES(${NAME} INTERFACE ${TPL_LINK_LIBRARIES})
    ENDIF()
    IF(TPL_INCLUDES)
      TARGET_INCLUDE_DIRECTORIES(${NAME} INTERFACE ${TPL_INCLUDES})
    ENDIF()
    IF(TPL_COMPILE_OPTIONS)
      TARGET_COMPILE_OPTIONS(${NAME} INTERFACE ${TPL_COMPILE_OPTIONS})
    ENDIF()
    IF(TPL_LINK_OPTIONS)
      TARGET_LINK_LIBRARIES(${NAME} INTERFACE ${TPL_LINK_OPTIONS})
    ENDIF()
  ELSE()
    ADD_LIBRARY(${NAME} UNKNOWN IMPORTED)
    IF(TPL_LIBRARY)
      SET_TARGET_PROPERTIES(${NAME} PROPERTIES
        IMPORTED_LOCATION ${TPL_LIBRARY})
    ENDIF()
    #Things have to go in quoted in case we have multiple list entries
    IF(TPL_LINK_LIBRARIES)
      SET_TARGET_PROPERTIES(${NAME} PROPERTIES
        INTERFACE_LINK_LIBRARIES "${TPL_LINK_LIBRARIES}")
    ENDIF()
    IF(TPL_INCLUDES)
      SET_TARGET_PROPERTIES(${NAME} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${TPL_INCLUDES}")
    ENDIF()
    IF(TPL_COMPILE_OPTIONS)
      SET_TARGET_PROPERTIES(${NAME} PROPERTIES
        INTERFACE_COMPILE_OPTIONS "${TPL_COMPILE_OPTIONS}")
    ENDIF()
    IF(TPL_LINK_OPTIONS)
      SET_TARGET_PROPERTIES(${NAME} PROPERTIES
        INTERFACE_LINK_LIBRARIES "${TPL_LINK_OPTIONS}")
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(kokkos_find_imported NAME)
  CMAKE_PARSE_ARGUMENTS(TPL
   "INTERFACE"
   "HEADER;LIBRARY;IMPORTED_NAME"
   "HEADER_PATHS;LIBRARY_PATHS;HEADERS;LIBRARIES"
   ${ARGN})

  IF (NOT TPL_IMPORTED_NAME)
    IF (TPL_INTERFACE)
      SET(TPL_IMPORTED_NAME ${NAME})
    ELSE()
      SET(TPL_IMPORTED_NAME Kokkos::${NAME})
    ENDIF()
  ENDIF()

  SET(${NAME}_INCLUDE_DIRS)
  IF (TPL_HEADER)
    IF(TPL_HEADER_PATHS)
      FIND_PATH(${NAME}_INCLUDE_DIRS ${TPL_HEADER} PATHS ${TPL_HEADER_PATHS})
    ELSE()
      FIND_PATH(${NAME}_INCLUDE_DIRS ${TPL_HEADER} PATHS ${${NAME}_ROOT}/include ${KOKKOS_${NAME}_DIR}/include)
    ENDIF()
  ENDIF()

  FOREACH(HEADER ${TPL_HEADERS})
    IF(TPL_HEADER_PATHS)
      FIND_LIBRARY(HEADER_FIND_TEMP ${HEADER} PATHS ${TPL_HEADER_PATHS})
    ELSE()
      FIND_LIBRARY(HEADER_FIND_TEMP ${HEADER} PATHS ${${NAME}_ROOT}/lib ${KOKKOS_${NAME}_DIR}/lib)
    ENDIF()
    IF(HEADER_FIND_TEMP)
      LIST(APPEND ${NAME}_INCLUDE_DIRS ${HEADER_FIND_TEMP})
    ENDIF()
  ENDFOREACH()

  SET(${NAME}_LIBRARY)
  IF(TPL_LIBRARY)
    IF(TPL_LIBRARY_PATHS)
      FIND_LIBRARY(${NAME}_LIBRARY ${TPL_LIBRARY} PATHS ${TPL_LIBRARY_PATHS})
    ELSE()
      FIND_LIBRARY(${NAME}_LIBRARY ${TPL_LIBRARY} PATHS ${${NAME}_ROOT}/lib ${KOKKOS_${NAME}_DIR}/lib)
    ENDIF()
  ENDIF()

  SET(${NAME}_LIBRARIES)
  FOREACH(LIB ${TPL_LIBRARIES})
    IF(TPL_LIBRARY_PATHS)
      FIND_LIBRARY(${LIB}_LOCATION ${LIB} PATHS ${TPL_LIBRARY_PATHS})
    ELSE()
      FIND_LIBRARY(${LIB}_LOCATION ${LIB} PATHS ${${NAME}_ROOT}/lib ${KOKKOS_${NAME}_DIR}/lib)
    ENDIF()
    IF(${LIB}_LOCATION)
      LIST(APPEND ${NAME}_LIBRARIES ${${LIB}_LOCATION})
    ELSE()
      SET(${NAME}_LIBRARIES ${${LIB}_LOCATION}) 
      BREAK()
    ENDIF()
  ENDFOREACH()

  INCLUDE(FindPackageHandleStandardArgs)
  IF (TPL_LIBRARY)
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(${NAME} DEFAULT_MSG ${NAME}_LIBRARY)
  ENDIF()
  IF(TPL_HEADER)
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(${NAME} DEFAULT_MSG ${NAME}_INCLUDE_DIRS)
  ENDIF()
  IF(TPL_LIBRARIES)
    FIND_PACKAGE_HANDLE_STANDARD_ARGS(${NAME} DEFAULT_MSG ${NAME}_LIBRARIES)
  ENDIF()

  MARK_AS_ADVANCED(${NAME}_INCLUDE_DIRS ${NAME}_LIBRARIES ${NAME}_LIBRARY)

  SET(IMPORT_TYPE)
  IF (TPL_INTERFACE)
    SET(IMPORT_TYPE "INTERFACE")
  ENDIF()
  KOKKOS_CREATE_IMPORTED_TPL(${TPL_IMPORTED_NAME}
    ${IMPORT_TYPE}
    INCLUDES "${${NAME}_INCLUDE_DIRS}"
    LIBRARY  "${${NAME}_LIBRARY}"
    LINK_LIBRARIES "${${NAME}_LIBRARIES}")
ENDMACRO(kokkos_find_imported)

FUNCTION(kokkos_link_tpl TARGET)
  CMAKE_PARSE_ARGUMENTS(TPL
   "PUBLIC;PRIVATE;INTERFACE"
   "IMPORTED_NAME"
   ""
   ${ARGN})
  #the name of the TPL
  SET(TPL ${TPL_UNPARSED_ARGUMENTS})
  IF (KOKKOS_HAS_TRILINOS)
    #Do nothing, they will have already been linked
  ELSE()
    IF (NOT TPL_IMPORTED_NAME)
      SET(TPL_IMPORTED_NAME Kokkos::${TPL})
    ENDIF()
    IF (KOKKOS_ENABLE_${TPL})
      IF (TPL_PUBLIC)
        TARGET_LINK_LIBRARIES(${TARGET} PUBLIC ${TPL_IMPORTED_NAME})
      ELSEIF (TPL_PRIVATE)
        TARGET_LINK_LIBRARIES(${TARGET} PRIVATE ${TPL_IMPORTED_NAME})
      ELSEIF (TPL_INTERFACE)
        TARGET_LINK_LIBRARIES(${TARGET} INTERFACE ${TPL_IMPORTED_NAME})
      ELSE()
        TARGET_LINK_LIBRARIES(${TARGET} ${TPL_IMPORTED_NAME})
      ENDIF()
    ENDIF()
  ENDIF()
ENDFUNCTION()

