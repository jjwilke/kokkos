#I have to leave these here for tribits
KOKKOS_INCLUDE_DIRECTORIES(
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${KOKKOS_TOP_BUILD_DIR}
)

FUNCTION(KOKKOS_APPEND_PCH LIST_NAME)
  CMAKE_PARSE_ARGUMENTS(PCH
    ""
    "FOLDER"
    "SUFFIXES"
    ${ARGN}
  )
  SET(HDR_PATHS)

  #We need some annoying logic if it's raw <...> vs <OpenMP/...>
  IF (PCH_FOLDER)
    SET(GLOB_PATH ${CMAKE_CURRENT_SOURCE_DIR}/${PCH_FOLDER})
    SET(PCH_PREFIX ${PCH_FOLDER}/)
  ELSE()
    SET(GLOB_PATH ${CMAKE_CURRENT_SOURCE_DIR})
    SET(PCH_PREFIX)
  ENDIF()

  IF (NOT PCH_SUFFIXES)
    SET(PCH_SUFFIXES hpp)
  ENDIF()

  FOREACH(SUFFIX ${PCH_SUFFIXES})
    APPEND_GLOB(HDR_PATHS ${GLOB_PATH}/*.${SUFFIX})
  ENDFOREACH()
  FOREACH(HDR_PATH ${HDR_PATHS})
    GET_FILENAME_COMPONENT(HDR ${HDR_PATH} NAME)
    LIST(APPEND ${LIST_NAME} ${PCH_PREFIX}${HDR})
  ENDFOREACH()
  SET(${LIST_NAME} ${${LIST_NAME}} PARENT_SCOPE)
ENDFUNCTION()

INSTALL (DIRECTORY
  "${CMAKE_CURRENT_SOURCE_DIR}/"
  DESTINATION ${KOKKOS_HEADER_DIR}
  FILES_MATCHING PATTERN "*.hpp"
)

SET(KOKKOS_CORE_SRCS)
SET(KOKKOS_PCH_HDRS "Kokkos_Core.hpp")
APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/impl/*.cpp)

IF (KOKKOS_ENABLE_ROCM)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/ROCm/*.cpp)
  KOKKOS_APPEND_PCH(KOKKOS_CORE_HDRS FOLDER ROCm)
  IF (KOKKOS_ENABLE_ETI)
    APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/eti/ROCm/*.cpp)
  ENDIF()
ENDIF()

IF (KOKKOS_ENABLE_CUDA)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/Cuda/*.cpp)
  KOKKOS_APPEND_PCH(KOKKOS_CORE_HDRS FOLDER Cuda)
  IF (KOKKOS_ENABLE_ETI)
    APPEND_GLOB(KOKKOS_CORE_SRC ${CMAKE_CURRENT_SOURCE_DIR/eti/Cuda/*.cpp)
  ENDIF()
ENDIF()

IF (KOKKOS_ENABLE_OPENMP)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/OpenMP/*.cpp)
  KOKKOS_APPEND_PCH(KOKKOS_PCH_HDRS FOLDER OpenMP)
  IF (KOKKOS_ENABLE_ETI)
    APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/eti/OpenMP/*.cpp)
  ENDIF()
ENDIF()
KOKKOS_APPEND_PCH(KOKKOS_PCH_HDRS) #current folder
#KOKKOS_APPEND_PCH(KOKKOS_PCH_HDRS FOLDER impl)

IF (KOKKOS_ENABLE_OPENMPTARGET)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/OpenMPTarget/*.cpp)
  APPEND_GLOB(KOKKOS_CORE_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/OpenMPTarget/*.hpp)
ENDIF()

IF (KOKKOS_ENABLE_PTHREAD)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/Threads/*.cpp)
  APPEND_GLOB(KOKKOS_CORE_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/Threads/*.hpp)
  IF (KOKKOS_ENABLE_ETI)
    APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/eti/Threads/*.cpp)
  ENDIF()
ENDIF()

IF (KOKKOS_ENABLE_HIP)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/HIP/*.cpp)
  APPEND_GLOB(KOKKOS_CORE_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/HIP/*.hpp)
ENDIF()

IF (KOKKOS_ENABLE_HPX)
  APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/HPX/*.cpp)
  APPEND_GLOB(KOKKOS_CORE_HDRS ${CMAKE_CURRENT_SOURCE_DIR}/HPX/*.hpp)
ENDIF()

IF (NOT KOKKOS_ENABLE_MEMKIND)
  LIST(REMOVE_ITEM KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/impl/Kokkos_HBWSpace.cpp)
ENDIF()

IF (KOKKOS_ENABLE_SERIAL)
  IF (KOKKOS_ENABLE_ETI)
    APPEND_GLOB(KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/eti/Serial/*.cpp)
  ENDIF()
ELSE()
  LIST(REMOVE_ITEM KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/impl/Kokkos_Serial.cpp)
  LIST(REMOVE_ITEM KOKKOS_CORE_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/impl/Kokkos_Serial_task.cpp)
ENDIF()


KOKKOS_ADD_LIBRARY(
  kokkoscore
  SOURCES ${KOKKOS_CORE_SRCS}
)

LIST(APPEND KOKKOS_PCH_HDRS
  impl/KokkosExp_Host_IterateTile.hpp
  impl/KokkosExp_ViewMapping.hpp
  impl/Kokkos_AnalyzePolicy.hpp
  impl/Kokkos_Atomic_Assembly.hpp
  impl/Kokkos_Atomic_Compare_Exchange_Strong.hpp
  impl/Kokkos_Atomic_Decrement.hpp
  impl/Kokkos_Atomic_Exchange.hpp
  impl/Kokkos_Atomic_Fetch_Add.hpp
  impl/Kokkos_Atomic_Fetch_And.hpp
  impl/Kokkos_Atomic_Fetch_Or.hpp
  impl/Kokkos_Atomic_Fetch_Sub.hpp
  impl/Kokkos_Atomic_Generic.hpp
  impl/Kokkos_Atomic_Increment.hpp
  impl/Kokkos_Atomic_Load.hpp
  impl/Kokkos_Atomic_Memory_Order.hpp
  impl/Kokkos_Atomic_Store.hpp
  impl/Kokkos_Atomic_View.hpp
  impl/Kokkos_Atomic_Windows.hpp
  impl/Kokkos_BitOps.hpp
  impl/Kokkos_CPUDiscovery.hpp
  impl/Kokkos_ChaseLev.hpp
  impl/Kokkos_ClockTic.hpp
  impl/Kokkos_ConcurrentBitset.hpp
  impl/Kokkos_EBO.hpp
  impl/Kokkos_Error.hpp
  impl/Kokkos_FixedBufferMemoryPool.hpp
  impl/Kokkos_FunctorAdapter.hpp
  impl/Kokkos_FunctorAnalysis.hpp
  impl/Kokkos_HostBarrier.hpp
  impl/Kokkos_HostSpace_deepcopy.hpp
  impl/Kokkos_HostThreadTeam.hpp
  impl/Kokkos_LIFO.hpp
  impl/Kokkos_LinkedListNode.hpp
  impl/Kokkos_MemoryPoolAllocator.hpp
  impl/Kokkos_MemorySpace.hpp
  impl/Kokkos_Memory_Fence.hpp
  impl/Kokkos_MultipleTaskQueue.hpp
  impl/Kokkos_OldMacros.hpp
  impl/Kokkos_OptionalRef.hpp
  impl/Kokkos_Profiling_DeviceInfo.hpp
  impl/Kokkos_Profiling_Interface.hpp
  impl/Kokkos_SharedAlloc.hpp
  impl/Kokkos_SimpleTaskScheduler.hpp
  impl/Kokkos_SingleTaskQueue.hpp
  impl/Kokkos_Spinwait.hpp
  impl/Kokkos_Stacktrace.hpp
  impl/Kokkos_Tags.hpp
  impl/Kokkos_TaskBase.hpp
  impl/Kokkos_TaskNode.hpp
  impl/Kokkos_TaskPolicyData.hpp
  impl/Kokkos_TaskQueue.hpp
  impl/Kokkos_TaskQueueCommon.hpp
  impl/Kokkos_TaskQueueMemoryManager.hpp
  impl/Kokkos_TaskQueueMultiple.hpp
  impl/Kokkos_TaskQueueMultiple_impl.hpp
  impl/Kokkos_TaskQueue_impl.hpp
  impl/Kokkos_TaskResult.hpp
  impl/Kokkos_TaskTeamMember.hpp
  impl/Kokkos_Timer.hpp
  impl/Kokkos_Traits.hpp
  impl/Kokkos_Utilities.hpp
  impl/Kokkos_VLAEmulation.hpp
  impl/Kokkos_ViewArray.hpp
  impl/Kokkos_ViewCtor.hpp
  impl/Kokkos_ViewFillCopyETIAvail.hpp
  impl/Kokkos_ViewFillCopyETIDecl.hpp
  impl/Kokkos_ViewLayoutTiled.hpp
  impl/Kokkos_ViewMapping.hpp
  impl/Kokkos_ViewTile.hpp
  impl/Kokkos_ViewUniformType.hpp
  impl/Kokkos_Volatile_Load.hpp
  KokkosExp_MDRangePolicy.hpp
  Kokkos_AnonymousSpace.hpp
  Kokkos_Array.hpp
  Kokkos_Atomic.hpp
  Kokkos_Complex.hpp
  Kokkos_Concepts.hpp
  Kokkos_CopyViews.hpp
  Kokkos_Core.hpp
  Kokkos_Core_fwd.hpp
  Kokkos_Crs.hpp
  Kokkos_CudaSpace.hpp
  Kokkos_ExecPolicy.hpp
  Kokkos_Extents.hpp
  Kokkos_Future.hpp
  Kokkos_HBWSpace.hpp
  Kokkos_HIP.hpp
  Kokkos_HIP_Space.hpp
  Kokkos_HPX.hpp
  Kokkos_HostSpace.hpp
  Kokkos_Layout.hpp
  Kokkos_Macros.hpp
  Kokkos_MasterLock.hpp
  Kokkos_MemoryPool.hpp
  Kokkos_MemoryTraits.hpp
  Kokkos_NumericTraits.hpp
  Kokkos_OpenMP.hpp
  Kokkos_Pair.hpp
  Kokkos_Parallel.hpp
  Kokkos_Parallel_Reduce.hpp
  Kokkos_PointerOwnership.hpp
  Kokkos_Profiling_ProfileSection.hpp
  Kokkos_ScratchSpace.hpp
  Kokkos_TaskPolicy.hpp
  Kokkos_TaskScheduler.hpp
  Kokkos_TaskScheduler_fwd.hpp
  Kokkos_Threads.hpp
  Kokkos_Timer.hpp
  Kokkos_UniqueToken.hpp
  Kokkos_Vectorization.hpp
  Kokkos_View.hpp
  Kokkos_WorkGraphPolicy.hpp
  Kokkos_hwloc.hpp
)

IF (KOKKOS_ENABLE_PCH)
  #PCH requires me to list only the header, not the full path
  FOREACH(HDR ${KOKKOS_PCH_HDRS})
    message("Have HDR=${HDR}")
  ENDFOREACH()
  TARGET_PRECOMPILE_HEADERS(kokkoscore PUBLIC
    ${KOKKOS_PCH_HDRS}
  )
ENDIF()



SET_TARGET_PROPERTIES(kokkoscore PROPERTIES VERSION ${Kokkos_VERSION})

KOKKOS_LIB_INCLUDE_DIRECTORIES(kokkoscore
  ${KOKKOS_TOP_BUILD_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
)

KOKKOS_LINK_TPL(kokkoscore PUBLIC HWLOC)
KOKKOS_LINK_TPL(kokkoscore PUBLIC MEMKIND)
KOKKOS_LINK_TPL(kokkoscore PUBLIC CUDA)
KOKKOS_LINK_TPL(kokkoscore PUBLIC HPX)
KOKKOS_LINK_TPL(kokkoscore PUBLIC LIBDL)
KOKKOS_LINK_TPL(kokkoscore PUBLIC LIBRT)
KOKKOS_LINK_TPL(kokkoscore PUBLIC PTHREAD)
