if(TARGET modules)
  # This module's own headers.
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # mod-playerbots headers (AddPlayerBot, PlayerbotFactory, AI factory and RandomItemMgr scoring).
  set(_PB_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src")
  if(EXISTS "${_PB_SRC}")
    target_include_directories(modules PRIVATE
      ${_PB_SRC}
      ${_PB_SRC}/Bot
      ${_PB_SRC}/Bot/Factory
      ${_PB_SRC}/Script
      ${_PB_SRC}/Ai/Base
      ${_PB_SRC}/Mgr/Item)
    message(STATUS "[mod-raid-roster] mod-playerbots headers on include path")
  else()
    message(WARNING "[mod-raid-roster] mod-playerbots not found; build will fail until it is cloned")
  endif()

  # Autonomous instance driving is delegated to the upstream dungeon-clear extension. The raid
  # roster integration only needs its public leader-election helper so we can start exactly the
  # elected bot tank rather than guessing which tank owns a party/raid run.
  set(_DC_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-dungeon-clear/src")
  if(EXISTS "${_DC_SRC}/Ai/Dungeon/DungeonClear/Util/DcLeaderSignal.h")
    target_include_directories(modules PRIVATE ${_DC_SRC})
    message(STATUS "[mod-raid-roster] mod-dungeon-clear autonomous navigation available")
  else()
    message(WARNING "[mod-raid-roster] mod-dungeon-clear not found; autonomous instance driving will not compile")
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
