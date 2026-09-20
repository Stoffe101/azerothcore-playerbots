CREATE TABLE IF NOT EXISTS `mod_adventure_progression_event` (
  `player_guid` INT UNSIGNED NOT NULL,
  `guild_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `group_size` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `killed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_guid`, `map_id`, `instance_id`, `creature_entry`),
  KEY `idx_guild_activity` (`guild_id`, `map_id`, `creature_entry`),
  KEY `idx_activity_time` (`map_id`, `creature_entry`, `killed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='Per-character instanced boss kill events for progression history';

CREATE TABLE IF NOT EXISTS `mod_adventure_progression_history` (
  `player_guid` INT UNSIGNED NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `first_guild_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `last_guild_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `first_group_size` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `last_group_size` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `clear_count` INT UNSIGNED NOT NULL DEFAULT 1,
  `first_kill_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_kill_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_guid`, `map_id`, `creature_entry`, `difficulty`),
  KEY `idx_activity` (`map_id`, `creature_entry`),
  KEY `idx_last_guild` (`last_guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='Per-character boss clear summary independent of bounty/economy settings';
