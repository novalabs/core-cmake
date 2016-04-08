IF( NOT WORKSPACE_PACKAGES_PATH )
  SET( WORKSPACE_PACKAGES_PATH ${NOVA_WORKSPACE_ROOT}/Generated/Packages )
ENDIF()
MESSAGE( STATUS "WORKSPACE_PACKAGES_PATH: ${WORKSPACE_PACKAGES_PATH}" )
MESSAGE( STATUS "WORKSPACE_PACKAGES_FIND_COMPONENTS: ${WORKSPACE_PACKAGES_FIND_COMPONENTS}" )

FOREACH(comp ${WORKSPACE_PACKAGES_FIND_COMPONENTS})
  INCLUDE( "${WORKSPACE_PACKAGES_PATH}/${comp}/${comp}Config.cmake" )
  #FIND_PACKAGE(comp CONFIG REQUIRED PATH ${WORKSPACE_PACKAGES_PATH}/${comp})

  FOREACH(source ${WORKSPACE_PACKAGES_${comp}_SOURCES})
    LIST(APPEND WORKSPACE_PACKAGES_SOURCES ${source})
  ENDFOREACH()

  FOREACH(include ${WORKSPACE_PACKAGES_${comp}_INCLUDES})
    LIST(APPEND WORKSPACE_PACKAGES_INCLUDES ${include})
  ENDFOREACH()
ENDFOREACH()

IF(WORKSPACE_PACKAGES_INCLUDES)
  LIST(REMOVE_DUPLICATES WORKSPACE_PACKAGES_INCLUDES)
ENDIF()

IF(WORKSPACE_PACKAGES_SOURCES)
  LIST(REMOVE_DUPLICATES WORKSPACE_PACKAGES_SOURCES)
ENDIF()