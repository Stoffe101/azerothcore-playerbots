CREATE TABLE IF NOT EXISTS `mod_smart_loot_pref` (
  `guid` INT UNSIGNED NOT NULL,
  `personal_loot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_bad_luck_streak` (
  `guid` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `boss_entry` INT UNSIGNED NOT NULL,
  `dry_kills` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_kill_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `map_id`, `boss_entry`),
  KEY `idx_mod_bad_luck_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
