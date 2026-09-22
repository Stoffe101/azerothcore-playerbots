if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # Synthetic arena-roster equipment consumes the central ERA-07 item chronology.
  set(_ERA_POLICY_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-raid-roster/src")
  if(EXISTS "${_ERA_POLICY_SRC}/EraPolicy.h")
    target_include_directories(modules PRIVATE ${_ERA_POLICY_SRC})
  else()
    message(FATAL_ERROR "[mod-arena-roster] central EraPolicy.h is required")
  endif()

  set(_PB_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src")
  if(EXISTS "${_PB_SRC}")
    target_include_directories(modules PRIVATE
      ${_PB_SRC}
      ${_PB_SRC}/Bot
      ${_PB_SRC}/Bot/Factory
      ${_PB_SRC}/Script
      ${_PB_SRC}/Ai/Base)
    message(STATUS "[mod-arena-roster] mod-playerbots headers on include path")
  else()
    message(WARNING "[mod-arena-roster] mod-playerbots not found; build will fail until it is cloned")
  endif()
endif()
