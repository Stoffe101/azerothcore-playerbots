if(TARGET modules)
  # This module's own headers.
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # mod-playerbots headers (AddPlayerBot, PlayerbotFactory, addclassCache, spec-tab enums).
  set(_PB_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src")
  if(EXISTS "${_PB_SRC}")
    target_include_directories(modules PRIVATE
      ${_PB_SRC}
      ${_PB_SRC}/Bot
      ${_PB_SRC}/Bot/Factory
      ${_PB_SRC}/Script
      ${_PB_SRC}/Ai/Base)
    message(STATUS "[mod-raid-roster] mod-playerbots headers on include path")
  else()
    message(WARNING "[mod-raid-roster] mod-playerbots not found; build will fail until it is cloned")
  endif()

  # The optional local raid-leader narration reuses the already-local Ollama bridge from
  # mod-playerbot-chatter. Both modules compile into AzerothCore's single modules target.
  set(_CHATTER_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbot-chatter/src")
  if(EXISTS "${_CHATTER_SRC}/PBChatterOllama.h")
    target_include_directories(modules PRIVATE ${_CHATTER_SRC})
    message(STATUS "[mod-raid-roster] local chatter/Ollama bridge available for grounded raid narration")
  else()
    message(WARNING "[mod-raid-roster] mod-playerbot-chatter not found; local raid narration will not compile")
  endif()
endif()
