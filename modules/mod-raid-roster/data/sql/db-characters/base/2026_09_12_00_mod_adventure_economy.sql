CREATE TABLE IF NOT EXISTS `mod_adventure_boss_bounty` (
  `player_guid` INT UNSIGNED NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `creature_entry` INT UNSIGNED NOT NULL,
  `reward_copper` INT UNSIGNED NOT NULL DEFAULT 0,
  `first_kill_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_guid`, `map_id`, `creature_entry`),
  KEY `idx_creature_entry` (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='One-time adventurer economy boss bounties per character';
