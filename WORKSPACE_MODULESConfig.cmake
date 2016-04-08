IF( NOT WORKSPACE_MODULES_PATH )
  SET( WORKSPACE_MODULES_PATH ${NOVA_WORKSPACE_ROOT}/Generated/Modules )
ENDIF()
MESSAGE( STATUS "WORKSPACE_MODULES_PATH: ${WORKSPACE_MODULES_PATH}" )
MESSAGE( STATUS "WORKSPACE_MODULES_FIND_COMPONENTS: ${WORKSPACE_MODULES_FIND_COMPONENTS}" )

FOREACH(comp ${WORKSPACE_MODULES_FIND_COMPONENTS}) 
  INCLUDE( "${WORKSPACE_MODULES_PATH}/${comp}/${comp}Config.cmake" )
  #FIND_PACKAGE(${comp} CONFIG REQUIRED PATH ${WORKSPACE_MODULES_PATH}/${comp})
  
  FOREACH(source ${WORKSPACE_MODULES_${comp}_SOURCES})
    LIST(APPEND WORKSPACE_MODULES_SOURCES ${source})
  ENDFOREACH()
  
  FOREACH(include ${WORKSPACE_MODULES_${comp}_INCLUDES})
    LIST(APPEND WORKSPACE_MODULES_INCLUDES ${include})
  ENDFOREACH()
  
  FOREACH(package ${WORKSPACE_MODULES_${comp}_REQUIRED_PACKAGES})

    LIST(APPEND MODULE_REQUIRED_PACKAGES ${package})
  ENDFOREACH()
  
  FOREACH(chibi_component ${WORKSPACE_MODULES_${comp}_CHIBIOS_REQUIRED_COMPONENTS})
    LIST(APPEND MODULE_CHIBIOS_REQUIRED_COMPONENTS ${chibi_component})
  ENDFOREACH()

ENDFOREACH()

IF(WORKSPACE_MODULES_INCLUDES)
  LIST(REMOVE_DUPLICATES WORKSPACE_MODULES_INCLUDES)
ENDIF()

IF(WORKSPACE_MODULES_SOURCES)
  LIST(REMOVE_DUPLICATES WORKSPACE_MODULES_SOURCES)
ENDIF()

IF(MODULE_REQUIRED_PACKAGES)
  LIST(REMOVE_DUPLICATES MODULE_REQUIRED_PACKAGES)
ENDIF()

IF(MODULE_CHIBIOS_REQUIRED_COMPONENTS)
  LIST(REMOVE_DUPLICATES MODULE_CHIBIOS_REQUIRED_COMPONENTS)
ENDIF()