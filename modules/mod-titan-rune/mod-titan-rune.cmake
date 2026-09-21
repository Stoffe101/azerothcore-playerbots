if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # Scripted vendors and reward helpers consume the central ERA-07 item chronology.
  set(_ERA_POLICY_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-raid-roster/src")
  if(EXISTS "${_ERA_POLICY_SRC}/EraPolicy.h")
    target_include_directories(modules PRIVATE ${_ERA_POLICY_SRC})
  else()
    message(FATAL_ERROR "[mod-titan-rune] central EraPolicy.h is required")
  endif()
endif()
