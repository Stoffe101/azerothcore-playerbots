if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # This control-center module intentionally consumes small public surfaces from several sibling
  # modules. Add their source include dirs explicitly instead of relying on module discovery order.
  set(_ADMIN_PANEL_DEPENDENCY_DIRS
    "${CMAKE_CURRENT_LIST_DIR}/../mod-raid-roster/src"
    "${CMAKE_CURRENT_LIST_DIR}/../mod-individual-progression/src"
    "${CMAKE_CURRENT_LIST_DIR}/../mod-era-talents/src"
    "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src"
    "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src/Bot"
    "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src/Bot/Factory"
  )

  foreach(_dep IN LISTS _ADMIN_PANEL_DEPENDENCY_DIRS)
    if(EXISTS "${_dep}")
      target_include_directories(modules PRIVATE "${_dep}")
    endif()
  endforeach()

  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../mod-raid-roster/src/AdventureStartControl.h")
    message(FATAL_ERROR "[mod-admin-panel] mod-raid-roster AdventureStartControl.h is required")
  endif()
  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../mod-individual-progression/src/IndividualProgression.h")
    message(FATAL_ERROR "[mod-admin-panel] mod-individual-progression is required")
  endif()
  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../mod-era-talents/src/EraTalents.h")
    message(FATAL_ERROR "[mod-admin-panel] mod-era-talents is required")
  endif()
  if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src/Bot/Factory/PlayerbotFactory.h")
    message(FATAL_ERROR "[mod-admin-panel] mod-playerbots is required")
  endif()
endif()
