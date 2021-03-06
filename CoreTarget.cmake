include(CMakeParseArguments)

find_program(OPENOCD openocd)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14") #-std=c++11

cmake_policy(SET CMP0005 NEW)

MACRO( core_target_module )

cmake_parse_arguments( CORE_TARGET "IS_BRIDGE" "MODULE;NAME;OS_VERSION" "PACKAGES;OS_COMPONENTS" ${ARGN} )
IF( CORE_TARGET_UNPARSED_ARGUMENTS )
  MESSAGE( FATAL_ERROR "CORE_TARGET_MODULE() called with unused arguments: ${CORE_TARGET_UNPARSED_ARGUMENTS}" )
ENDIF()

ENABLE_LANGUAGE( ASM )

MESSAGE( STATUS "Core Target Is Bridge: ${CORE_TARGET_IS_BRIDGE}" )
MESSAGE( STATUS "Core Target Module: ${CORE_TARGET_MODULE}" )
MESSAGE( STATUS "Core Target OS Version: ${CORE_TARGET_OS_VERSION}" )
MESSAGE( STATUS "Core Target Packages: ${CORE_MODULE_PACKAGES}" )

IF( "${CORE_TARGET_NAME}" STREQUAL "" )
  SET( MODULE_NAME "${CMAKE_PROJECT_NAME}" )
ELSE()
  SET( MODULE_NAME "${CORE_TARGET_NAME}" )
ENDIF()

MESSAGE( STATUS "Core Target Module Name: ${MODULE_NAME}" )

FIND_PACKAGE( WORKSPACE_MODULES CONFIG COMPONENTS ${CORE_TARGET_MODULE} REQUIRED )

SET( CORE_USE_RTCANTRANSPORT TRUE )
SET( CORE_USE_DEBUGTRANSPORT TRUE ) # DAVIDE

IF( CORE_TARGET_PACKAGES )
  LIST( APPEND MODULE_REQUIRED_PACKAGES ${CORE_TARGET_PACKAGES} )
ENDIF()

LIST( REMOVE_DUPLICATES MODULE_REQUIRED_PACKAGES )

IF( CORE_TARGET_OS_COMPONENTS )
  LIST( APPEND MODULE_CHIBIOS_REQUIRED_COMPONENTS ${CORE_TARGET_OS_COMPONENTS} )
ENDIF()

LIST( REMOVE_DUPLICATES MODULE_CHIBIOS_REQUIRED_COMPONENTS )


IF("${CORE_TARGET_OS_VERSION}" STREQUAL "CHIBIOS_3")
  FIND_PACKAGE(ChibiOS 3 COMPONENTS ${MODULE_CHIBIOS_REQUIRED_COMPONENTS} REQUIRED)
ELSEIF("${CORE_TARGET_OS_VERSION}" STREQUAL "CHIBIOS_16")
  FIND_PACKAGE(ChibiOS 16 COMPONENTS ${MODULE_CHIBIOS_REQUIRED_COMPONENTS} REQUIRED)
ENDIF()
  
FIND_PACKAGE(NovaCore_Base REQUIRED)
FIND_PACKAGE(NovaCore_OS REQUIRED)
FIND_PACKAGE(NovaCore_MW REQUIRED)
FIND_PACKAGE(NovaCore_HW REQUIRED)
FIND_PACKAGE(NovaCore_Utils REQUIRED)

FIND_PACKAGE(Nova_RTCAN REQUIRED)
FIND_PACKAGE( WORKSPACE_PACKAGES CONFIG COMPONENTS ${MODULE_REQUIRED_PACKAGES} REQUIRED )

MESSAGE( STATUS "MODULE_REQUIRED_PACKAGES: ${MODULE_REQUIRED_PACKAGES}" )

SET( ALL_INCLUDES 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${NOVA_CORE_BASE_INCLUDE_DIRS}
    ${NOVA_CORE_OS_INCLUDE_DIRS}
    ${NOVA_CORE_MW_INCLUDE_DIRS}
    ${NOVA_CORE_HW_INCLUDE_DIRS}
    ${NOVA_CORE_UTILS_INCLUDE_DIRS}
    ${NOVA_RTCAN_INCLUDE_DIRS}
    ${WORKSPACE_PACKAGES_INCLUDES}
    ${ChibiOS_INCLUDE_DIRS}
    ${WORKSPACE_MODULES_INCLUDES}
    ${PROJECT_INCLUDE_DIRECTORIES}
    ${CMAKE_BINARY_DIR}
)

INCLUDE_DIRECTORIES(
    ${ALL_INCLUDES}
)

MESSAGE( STATUS "WORKSPACE_PACKAGES_INCLUDES: ${WORKSPACE_PACKAGES_INCLUDES}" )
MESSAGE( STATUS "INCLUDE_DIRECTORIES: ${ALL_INCLUDES}" )

MESSAGE( STATUS "WORKSPACE_PACKAGES_DEFINITIONS: ${WORKSPACE_PACKAGES_DEFINITIONS}" )

FOREACH( D ${WORKSPACE_PACKAGES_DEFINITIONS})
    ADD_DEFINITIONS( -D${D} )
ENDFOREACH()

MESSAGE( STATUS "CHIBIOS_COMPONENTS_DEFINITIONS: ${CHIBIOS_COMPONENTS_DEFINITIONS}" )

FOREACH( D ${CHIBIOS_COMPONENTS_DEFINITIONS})
    ADD_DEFINITIONS( -D${D} )
ENDFOREACH()

ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_SOURCE_DIR}/getGITVersion.sh ${CMAKE_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/GIT_REVISION.h ${CMAKE_BINARY_DIR}/GIT_REVISION.h
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_SOURCE_DIR}/GIT_REVISION.h
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Creates/updates header GIT Revision Header"
)

add_custom_target(GIT_REVISION DEPENDS ${CMAKE_BINARY_DIR}/GIT_REVISION.h)

IF(EXISTS "${CMAKE_SOURCE_DIR}/getGITVersion.sh")
ADD_DEPENDENCIES("firmware" GIT_REVISION)
ENDIF()

include(GetGitRevisionDescription)

git_describe_dirty(WRKS_GIT_DESC ${CMAKE_SOURCE_DIR})
git_describe_dirty(CORE_GIT_DESC ${NOVA_ROOT})

IF(EXISTS "${CMAKE_SOURCE_DIR}/GITRevisionTemplate.cpp.in")
  ADD_DEFINITIONS(-DHAS_GIT_DESC)
  
  STRING(REGEX MATCH ".*-dirty" WRKS_IS_DIRTY ${WRKS_GIT_DESC})
  IF(WRKS_IS_DIRTY) 
    #SET(WRKS_GIT_DESC "DIRTY")
    ADD_DEFINITIONS(-DWRKS_IS_DIRTY)
    MESSAGE( STATUS "WORKSPACE IS DIRTY: ${WRKS_GIT_DESC}" )
  ELSE()
    MESSAGE( STATUS "WRKS_GIT_DESC: ${WRKS_GIT_DESC}" )
  ENDIF()

  STRING(REGEX MATCH ".*-dirty" CORE_IS_DIRTY ${CORE_GIT_DESC})
  IF(CORE_IS_DIRTY) 
    #SET(CORE_GIT_DESC "DIRTY")
    ADD_DEFINITIONS(-DCORE_IS_DIRTY)
    MESSAGE( STATUS "CORE IS DIRTY: ${CORE_GIT_DESC}" )
  ELSE()
    MESSAGE( STATUS "CORE_GIT_DESC: ${CORE_GIT_DESC}" )
  ENDIF()
  
  configure_file("${CMAKE_SOURCE_DIR}/GITRevisionTemplate.cpp.in" "${CMAKE_BINARY_DIR}/GITRevision.cpp" @ONLY)
  
  file(WRITE "${CMAKE_BINARY_DIR}/revisions.txt" "${CORE_GIT_DESC}_${WRKS_GIT_DESC}" )
  file(WRITE "${CMAKE_BINARY_DIR}/wrks_revision.txt" "${WRKS_GIT_DESC}" )
  file(WRITE "${CMAKE_BINARY_DIR}/core_revision.txt" "${CORE_GIT_DESC}" )
  
  list(APPEND REVISION_SOURCES "${CMAKE_BINARY_DIR}/GITRevision.cpp")
ENDIF()

ADD_DEFINITIONS(-DCORE_MODULE_NAME="${MODULE_NAME}")

IF(STM32_FAMILY STREQUAL "F3")
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=TRUE)
ELSEIF(STM32_FAMILY STREQUAL "F4")
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=TRUE)
ELSE()
    ADD_DEFINITIONS(-DCORTEX_USE_FPU=FALSE)
ENDIF()
ADD_DEFINITIONS(-D${STM32_CHIP})

STRING(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
IF(${BUILD_TYPE} STREQUAL "debug")
  ADD_DEFINITIONS(-D_DEBUG)
ENDIF()

IF(${CORE_TARGET_IS_BRIDGE})
  ADD_DEFINITIONS(-DCORE_ITERATE_PUBSUB=1 -DCORE_USE_BRIDGE_MODE=1 )
ELSE()
  ADD_DEFINITIONS(-DCORE_ITERATE_PUBSUB=1 -DCORE_USE_BRIDGE_MODE=0 )
ENDIF()
ADD_DEFINITIONS(-DUSE_CORE_ASSERT)
ADD_DEFINITIONS(-DCHPRINTF_USE_FLOAT=TRUE)

IF(${CORE_USE_RTCANTRANSPORT})
  ADD_DEFINITIONS(-DUSE_RTCANTRANSPORT)
ENDIF()

IF(${CORE_USE_DEBUGTRANSPORT})
  ADD_DEFINITIONS(-DUSE_DEBUGTRANSPORT)
ENDIF()

SET (CORTEX_VTOR_INIT 0 )

# BOOTLOADER
IF(NOT BOOTLOADER_SIZE)
  SET(BOOTLOADER_SIZE 0)
ENDIF()

MESSAGE( STATUS "BOOTLOADER_SIZE: ${BOOTLOADER_SIZE}" )
ADD_DEFINITIONS(-DBOOTLOADER_SIZE=${BOOTLOADER_SIZE})

IF(BOOTLOADER_SIZE GREATER 0)
  ADD_DEFINITIONS(-DCORTEX_ALTERNATE_SWITCH=TRUE)
  ADD_DEFINITIONS(-DCORE_USE_BOOTLOADER=1)
ELSE()
  ADD_DEFINITIONS(-DCORE_USE_BOOTLOADER=0)
ENDIF()

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

# TAGS
IF(NOT TAGS_SIZE)
  SET(TAGS_SIZE 0)
ENDIF()

MESSAGE( STATUS "TAGS_SIZE: ${TAGS_SIZE}" )
ADD_DEFINITIONS(-DTAGS_SIZE=${TAGS_SIZE})

STM32_GET_CHIP_PARAMETERS(${STM32_CHIP}  STM32_FLASH_SIZE STM32_RAM_SIZE STM32_CCM_RAM_SIZE )

MATH(EXPR PROGRAM_SIZE "(1024*${STM32_FLASH_SIZE})-${BOOTLOADER_SIZE}-${CONFIGURATION_SIZE}-${CONFIGURATION_SIZE}")
MESSAGE( STATUS "PROGRAM SIZE: ${PROGRAM_SIZE}" )

ADD_DEFINITIONS(-DCORTEX_VTOR_INIT=BOOTLOADER_SIZE+CONFIGURATION_SIZE+CONFIGURATION_SIZE)

SET(STM32_LINKER_SCRIPT ${ChibiOS_LINKER_SCRIPT})

ADD_EXECUTABLE("firmware"
  ${WORKSPACE_MODULES_SOURCES}
  ${ChibiOS_SOURCES}
  ${NOVA_CORE_BASE_SOURCES}
  ${NOVA_CORE_OS_SOURCES}
  ${NOVA_CORE_MW_SOURCES}
  ${NOVA_CORE_HW_SOURCES}
  ${NOVA_CORE_UTILS_SOURCES}
  ${NOVA_RTCAN_SOURCES}
  ${WORKSPACE_PACKAGES_SOURCES}
  ${REVISION_SOURCES}
  ${PROJECT_SOURCES}
)

TARGET_LINK_LIBRARIES("firmware")

STM32_SET_TARGET_PROPERTIES("firmware")
STM32_ADD_HEX_BIN_TARGETS("firmware")
STM32_PRINT_SIZE_OF_TARGETS("firmware")

FUNCTION(ADD_DEPLOY_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
      SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
      SET(FILENAME "${TARGET}")
    ENDIF()
    ADD_CUSTOM_TARGET(deploy DEPENDS ${TARGET} 
        COMMAND ${CMAKE_COMMAND} -E copy ${FILENAME} ${TARGET}_${MODULE_NAME}_${WRKS_GIT_DESC}.elf
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/wrks_revision.txt ${TARGET}_${MODULE_NAME}.revision
        COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${TARGET}_${MODULE_NAME}_${WRKS_GIT_DESC}.hex
        COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${TARGET}_${MODULE_NAME}_${WRKS_GIT_DESC}.bin
        COMMAND CoreHexCRC.py "${TARGET}_${MODULE_NAME}_${WRKS_GIT_DESC}.hex" ${PROGRAM_SIZE} > ${TARGET}_${MODULE_NAME}_${WRKS_GIT_DESC}.crc
    )
ENDFUNCTION()

ADD_DEPLOY_TARGETS("firmware")

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
        DEPENDS firmware
        COMMAND ${OPENOCD} -f 'interface/stlink-v2.cfg' -f 'target/${TARGET_FILE}'
          -c 'init'
          -c 'reset init'
          -c 'halt'
          -c 'flash write_image erase firmware'
          -c 'shutdown'
      )
  ENDIF()
ENDIF()

add_custom_target(firmware.crc
        DEPENDS firmware.hex
        COMMAND CoreHexCRC.py firmware.hex ${PROGRAM_SIZE} > firmware.crc
)

ENDMACRO()
