CREATE TABLE IF NOT EXISTS `mod_adventure_progression_clear` (
  `activity_id` VARCHAR(64) NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `group_size` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `killed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`map_id`, `instance_id`, `creature_entry`),
  KEY `idx_activity_clear_time` (`activity_id`, `killed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='One durable catalog-recognized final-boss clear per instance';

CREATE TABLE IF NOT EXISTS `mod_adventure_progression_clear_member` (
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `member_guid` INT UNSIGNED NOT NULL,
  `member_name` VARCHAR(24) NOT NULL,
  `guild_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `is_playerbot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `class_id` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`map_id`, `instance_id`, `creature_entry`, `member_guid`),
  KEY `idx_member_guid` (`member_guid`),
  KEY `idx_member_guild` (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='Participant snapshot for a durable progression clear';

CREATE TABLE IF NOT EXISTS `mod_adventure_progression_guild_clear` (
  `guild_id` INT UNSIGNED NOT NULL,
  `activity_id` VARCHAR(64) NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `difficulty` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `group_size` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `killed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`, `map_id`, `instance_id`, `creature_entry`),
  KEY `idx_guild_activity_clear` (`guild_id`, `activity_id`, `killed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='Guild-specific durable progression clears referencing shared clear snapshots';
