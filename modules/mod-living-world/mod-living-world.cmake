if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)
  set(_PB_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src")
  if(EXISTS "${_PB_SRC}")
    target_include_directories(modules PRIVATE
      ${_PB_SRC}
      ${_PB_SRC}/Bot
      ${_PB_SRC}/Bot/Factory
      ${_PB_SRC}/Script
      ${_PB_SRC}/Ai/Base
      ${_PB_SRC}/Mgr/Guild)
  endif()
endif()
