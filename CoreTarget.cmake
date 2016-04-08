include(CMakeParseArguments)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

cmake_policy(SET CMP0005 NEW)
#INCLUDE ( "/home/davide/Work/Nova/BuildSystem/sandbox2/Core/nova-cmake/gcc_stm32.cmake" )

MACRO( core_target_module )

cmake_parse_arguments( CORE_TARGET "" "MODULE;NAME" "PACKAGES" ${ARGN} )
IF( CORE_TARGET_UNPARSED_ARGUMENTS )
  MESSAGE( FATAL_ERROR "CORE_TARGET_MODULE() called with unused arguments: ${CORE_TARGET_UNPARSED_ARGUMENTS}" )
ENDIF()

ENABLE_LANGUAGE( ASM )

MESSAGE( STATUS "Core Target Module: ${CORE_TARGET_MODULE}" )
MESSAGE( STATUS "Core Target Packages: ${CORE_MODULE_PACKAGES}" )

IF( "${CORE_TARGET_NAME}" STREQUAL "" )
  SET( MODULE_NAME "${CMAKE_PROJECT_NAME}" )
ELSE()
  SET( MODULE_NAME "${CORE_TARGET_NAME}" )
ENDIF()

MESSAGE( STATUS "Core Target Module Name: ${MODULE_NAME}" )

FIND_PACKAGE( WORKSPACE_MODULES CONFIG COMPONENTS ${CORE_TARGET_MODULE} REQUIRED )

SET( CORE_USE_RTCANTRANSPORT TRUE )
SET( CORE_USE_DEBUGTRANSPORT FALSE )

IF( CORE_TARGET_PACKAGES )
  LIST( APPEND MODULE_REQUIRED_PACKAGES ${CORE_TARGET_PACKAGES} )
ENDIF()

LIST( REMOVE_DUPLICATES MODULE_REQUIRED_PACKAGES )

FIND_PACKAGE(ChibiOS COMPONENTS ${MODULE_CHIBIOS_REQUIRED_COMPONENTS} REQUIRED)
FIND_PACKAGE(Nova_MW REQUIRED)
FIND_PACKAGE(Nova_RTCAN REQUIRED)
FIND_PACKAGE( WORKSPACE_PACKAGES CONFIG COMPONENTS ${MODULE_REQUIRED_PACKAGES} REQUIRED )

MESSAGE( STATUS "MODULE_REQUIRED_PACKAGES: ${MODULE_REQUIRED_PACKAGES}" )

INCLUDE_DIRECTORIES(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${NOVA_MW_INCLUDE_DIRS}
    ${NOVA_RTCAN_INCLUDE_DIRS}
    ${WORKSPACE_PACKAGES_INCLUDES}
    ${ChibiOS_INCLUDE_DIRS}
    ${WORKSPACE_MODULES_INCLUDES}
    ${PROJECT_INCLUDE_DIRECTORIES}
)

MESSAGE( STATUS "WORKSPACE_PACKAGES_INCLUDES: ${WORKSPACE_PACKAGES_INCLUDES}" )



ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_SOURCE_DIR}/getGITVersion.sh ${CMAKE_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/GIT_REVISION.h ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_SOURCE_DIR}/GIT_REVISION.h
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Creates/updates header GIT Revision Header"
)

#add_custom_target(Foo DEPENDS ${CMAKE_BINARY_DIR}/GIT_REVISION.h)

ADD_DEFINITIONS(-DCORE_MODULE_NAME="${MODULE_NAME}")
ADD_DEFINITIONS(-DCORTEX_USE_FPU=TRUE)
ADD_DEFINITIONS(-DCORE_ITERATE_PUBSUB=1 -DCORE_USE_BRIDGE_MODE=0 -DCORE_USE_BOOTLOADER=0)
ADD_DEFINITIONS(-DUSE_CORE_ASSERT)
ADD_DEFINITIONS(-DCHPRINTF_USE_FLOAT=TRUE)


SET(STM32_LINKER_SCRIPT ${ChibiOS_LINKER_SCRIPT})

ADD_EXECUTABLE(${CMAKE_PROJECT_NAME} ${WORKSPACE_MODULES_SOURCES} ${ChibiOS_SOURCES} ${NOVA_MW_SOURCES} ${NOVA_RTCAN_SOURCES} ${WORKSPACE_PACKAGES_SOURCES} ${PROJECT_SOURCES} )
#ADD_DEPENDENCIES(${CMAKE_PROJECT_NAME} Foo)

TARGET_LINK_LIBRARIES(${CMAKE_PROJECT_NAME})

STM32_SET_TARGET_PROPERTIES(${CMAKE_PROJECT_NAME})
STM32_ADD_HEX_BIN_TARGETS(${CMAKE_PROJECT_NAME})

ENDMACRO()
