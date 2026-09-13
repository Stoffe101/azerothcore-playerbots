if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # The admin panel can switch AdventureStart's runtime default and invoke the raid-ready boost.
  set(_RAID_START_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-raid-roster/src")
  if(EXISTS "${_RAID_START_SRC}/AdventureStartControl.h")
    target_include_directories(modules PRIVATE ${_RAID_START_SRC})
  else()
    message(WARNING "[mod-admin-panel] mod-raid-roster AdventureStartControl.h not found; build requires the local raid-roster module")
  endif()
endif()
