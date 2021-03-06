SET(ARDUINO_JSON ${NOVA_ROOT}/libs/ArduinoJson)
MESSAGE( STATUS "ARDUINO_JSON: ${ARDUINO_JSON}" )

IF( NOT EXISTS ${ARDUINO_JSON})
  MESSAGE( FATAL_ERROR "${ARDUINO_JSON} does not exists." )
ENDIF()

SET(ARDUINO_JSON_SRC
)

SET(ARDUINO_JSON_SOURCES ${ARDUINO_JSON_SRC})

SET( ARDUINO_JSON_INCLUDE_DIRS
        ${ARDUINO_JSON}/src
)


#LIST( REMOVE_DUPLICATES ARDUINO_JSON_SOURCES )
LIST( REMOVE_DUPLICATES ARDUINO_JSON_INCLUDE_DIRS )

INCLUDE( FindPackageHandleStandardArgs )
FIND_PACKAGE_HANDLE_STANDARD_ARGS( ARDUINO_JSON DEFAULT_MSG ARDUINO_JSON_SOURCES ARDUINO_JSON_INCLUDE_DIRS )
