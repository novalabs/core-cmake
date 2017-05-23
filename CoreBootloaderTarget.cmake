include(CMakeParseArguments)

find_program(OPENOCD openocd)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

cmake_policy(SET CMP0005 NEW)

MACRO( core_bootloader_target_module )

SET(BOOTLOADER_TARGET 1)

cmake_parse_arguments( CORE_TARGET "" "MODULE;NAME;OS_VERSION" "PACKAGES" ${ARGN} )
IF( CORE_TARGET_UNPARSED_ARGUMENTS )
  MESSAGE( FATAL_ERROR "CORE_TARGET_MODULE() called with unused arguments: ${CORE_TARGET_UNPARSED_ARGUMENTS}" )
ENDIF()

ENABLE_LANGUAGE( ASM )

MESSAGE( STATUS "Core Bootloader Target Module: ${CORE_TARGET_MODULE}" )
MESSAGE( STATUS "Core Bootloader Target Name: ${CORE_TARGET_NAME}" )
MESSAGE( STATUS "Core Bootloader Target OS Version: ${CORE_TARGET_OS_VERSION}" )
MESSAGE( STATUS "Core Bootloader Target Packages: ${CORE_MODULE_PACKAGES}" )

IF( "${CORE_TARGET_NAME}" STREQUAL "" )
  SET( MODULE_NAME "${CMAKE_PROJECT_NAME}" )
ELSE()
  SET( MODULE_NAME "${CORE_TARGET_NAME}" )
ENDIF()

MESSAGE( STATUS "Core Bootloader Target Module Name: ${MODULE_NAME}" )

FIND_PACKAGE( WORKSPACE_MODULES CONFIG COMPONENTS ${CORE_TARGET_MODULE} REQUIRED )

SET( CORE_USE_RTCANTRANSPORT TRUE )
SET( CORE_USE_DEBUGTRANSPORT FALSE )

LIST( APPEND MODULE_REQUIRED_PACKAGES "stm32_flash" "stm32_crc" )

IF( CORE_TARGET_PACKAGES )
  LIST( APPEND MODULE_REQUIRED_PACKAGES ${CORE_TARGET_PACKAGES} )
ENDIF()

LIST( REMOVE_DUPLICATES MODULE_REQUIRED_PACKAGES )

IF("${CORE_TARGET_OS_VERSION}" STREQUAL "CHIBIOS_3")
  FIND_PACKAGE(ChibiOS 3 COMPONENTS ${MODULE_CHIBIOS_REQUIRED_COMPONENTS} REQUIRED)
ELSEIF("${CORE_TARGET_OS_VERSION}" STREQUAL "CHIBIOS_16")
  FIND_PACKAGE(ChibiOS 16 COMPONENTS ${MODULE_CHIBIOS_REQUIRED_COMPONENTS} REQUIRED)
ENDIF()
  
FIND_PACKAGE(Nova_RTCAN REQUIRED)
FIND_PACKAGE(NovaCore_Bootloader REQUIRED)

FIND_PACKAGE( WORKSPACE_PACKAGES CONFIG COMPONENTS ${MODULE_REQUIRED_PACKAGES} REQUIRED )

MESSAGE( STATUS "MODULE_REQUIRED_PACKAGES: ${MODULE_REQUIRED_PACKAGES}" )

INCLUDE_DIRECTORIES(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${ChibiOS_INCLUDE_DIRS}
    ${WORKSPACE_PACKAGES_INCLUDES}
    ${NOVA_RTCAN_INCLUDE_DIRS}
    ${WORKSPACE_MODULES_INCLUDES}
    ${NOVA_CORE_BOOTLOADER_INCLUDE_DIRS}
    ${PROJECT_INCLUDE_DIRECTORIES}
)

MESSAGE( STATUS "WORKSPACE_PACKAGES_INCLUDES: ${WORKSPACE_PACKAGES_INCLUDES}" )

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_SOURCE_DIR}/getGITVersion.sh ${CMAKE_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/GIT_REVISION.h ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_SOURCE_DIR}/GIT_REVISION.h
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Creates/updates header GIT Revision Header"
)


set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

#add_custom_target(Foo DEPENDS ${CMAKE_BINARY_DIR}/GIT_REVISION.h)

ADD_DEFINITIONS(-DCORE_MODULE_NAME="${MODULE_NAME}")
ADD_DEFINITIONS(-DCORE_IS_BOOTLOADER=TRUE)

IF(STM32_FAMILY STREQUAL "F3")
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=TRUE)
ELSEIF(STM32_FAMILY STREQUAL "F4")
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=TRUE)
ELSE()
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=FALSE)
ENDIF()

ADD_DEFINITIONS(-DSTOP_IWDG_ON_DEBUG)

# BOOTLOADER
IF(NOT BOOTLOADER_SIZE)
  SET(BOOTLOADER_SIZE 0)
ENDIF()

MESSAGE( STATUS "BOOTLOADER_SIZE: ${BOOTLOADER_SIZE}" )
ADD_DEFINITIONS(-DBOOTLOADER_SIZE=${BOOTLOADER_SIZE})

# CONFIGURATION
IF(NOT CONFIGURATION_SIZE)
  SET(CONFIGURATION_SIZE 0)
ENDIF()

MESSAGE( STATUS "CONFIGURATION_SIZE: ${CONFIGURATION_SIZE}" )
ADD_DEFINITIONS(-DCONFIGURATION_SIZE=${CONFIGURATION_SIZE})

IF(CONFIGURATION_SIZE GREATER 0)
  ADD_DEFINITIONS(-DCORE_USE_CONFIGURATION_STORAGE=1)
ELSE()
  ADD_DEFINITIONS(-DCORE_USE_CONFIGURATION_STORAGE=0)
ENDIF()


SET(STM32_LINKER_SCRIPT ${ChibiOS_LINKER_SCRIPT})

set(SOURCE_FILES
  ${WORKSPACE_MODULES_SOURCES}
  ${ChibiOS_SOURCES}
  ${NOVA_RTCAN_SOURCES}
  ${WORKSPACE_PACKAGES_SOURCES}
  ${NOVA_CORE_BOOTLOADER_SOURCES}
  ${PROJECT_SOURCES}
)

add_executable("bootloader"
  ${SOURCE_FILES}
)

MESSAGE( STATUS "SOURCE_FILES: ${SOURCE_FILES}" )


TARGET_LINK_LIBRARIES("bootloader")

STM32_SET_TARGET_PROPERTIES("bootloader")
STM32_ADD_HEX_BIN_TARGETS("bootloader")
STM32_PRINT_SIZE_OF_TARGETS("bootloader")

IF(OPENOCD)
  IF(STM32_FAMILY STREQUAL "F0")
      SET(TARGET_FILE "stm32f0x_stlink.cfg")
  ELSEIF(STM32_FAMILY STREQUAL "F3")
      SET(TARGET_FILE "stm32f3x_stlink.cfg")
  ELSEIF(STM32_FAMILY STREQUAL "F4")
      SET(TARGET_FILE "stm32f4x_stlink.cfg")
  ELSE()
      SET(TARGET_FILE "- none -")
  ENDIF()
  
  MESSAGE( STATUS "openocd found: ${OPENOCD}" )
  MESSAGE( STATUS "openocd target file: ${TARGET_FILE}" )
  IF(TARGET_FILE STREQUAL "- none -")
    MESSAGE( STATUS "Skipping..." )
  ELSE()
      add_custom_target(flash
        DEPENDS bootloader
        COMMAND ${OPENOCD} -f 'interface/stlink-v2.cfg' -f 'target/${TARGET_FILE}'
          -c 'init'
          -c 'reset init'
          -c 'halt'
          -c 'flash write_image erase bootloader'
          -c 'shutdown'
      )
  ENDIF()
ENDIF()

ENDMACRO()
