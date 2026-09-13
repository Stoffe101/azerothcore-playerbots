CREATE TABLE IF NOT EXISTS `mod_adventure_progression` (
  `player_guid` INT UNSIGNED NOT NULL,
  `starter_initialized` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `starter_gear_granted` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `starter_spec_tab` TINYINT UNSIGNED NOT NULL DEFAULT 255,
  `pending_caches` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_level_cache` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
