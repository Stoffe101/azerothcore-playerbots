CREATE TABLE IF NOT EXISTS `mod_adventure_daily_activity` (
  `player_guid` INT UNSIGNED NOT NULL,
  `reward_date` DATE NOT NULL,
  `earned_copper` INT UNSIGNED NOT NULL DEFAULT 0,
  `boss_kills` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_guid`, `reward_date`),
  KEY `idx_reward_date` (`reward_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Daily-capped repeat dungeon and raid activity rewards';
