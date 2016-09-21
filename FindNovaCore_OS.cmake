IF( NOT NOVA_CORE_OS_ROOT )
  IF( NOT NOVA_ROOT )
    SET( NOVA_CORE_OS_ROOT /opt/nova/core-os )
  ELSE()
    SET( NOVA_CORE_OS_ROOT ${NOVA_ROOT}/core-os )
  ENDIF()

  MESSAGE( STATUS "No NOVA_CORE_OS_ROOT specified, using default: ${NOVA_CORE_OS_ROOT}" )
ENDIF()

SET( NOVA_CORE_OS_SOURCES
  ${NOVA_CORE_OS_ROOT}/src/core-os.cpp
  
  ${NOVA_CORE_OS_ROOT}/src/Time.cpp
  
  ${NOVA_CORE_OS_ROOT}/port/chibios/src/impl/Time_.cpp
  ${NOVA_CORE_OS_ROOT}/port/chibios/src/impl/Stubs.cpp
)

SET( NOVA_CORE_OS_INCLUDE_DIRS
  ${NOVA_CORE_OS_ROOT}/include
  ${NOVA_CORE_OS_ROOT}/port/chibios/include
)

IF( NOVA_CORE_OS_SOURCES )
  LIST( REMOVE_DUPLICATES NOVA_CORE_OS_SOURCES )
ENDIF()

IF( NOVA_CORE_OS_INCLUDE_DIRS )
  LIST( REMOVE_DUPLICATES NOVA_CORE_OS_INCLUDE_DIRS )
ENDIF()

INCLUDE( FindPackageHandleStandardArgs )
FIND_PACKAGE_HANDLE_STANDARD_ARGS( NovaCore_OS DEFAULT_MSG NOVA_CORE_OS_SOURCES NOVA_CORE_OS_INCLUDE_DIRS )