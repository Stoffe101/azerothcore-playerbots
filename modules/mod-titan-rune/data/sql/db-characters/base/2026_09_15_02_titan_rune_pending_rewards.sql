-- Titan Rune scripted currencies are granted outside the normal loot container. Persist each
-- player's entitlement before marking the boss globally rewarded so full bags or a server restart
-- cannot eat a Sidereal Essence / Defiler's Scourgestone and cannot duplicate a successful payout.
CREATE TABLE IF NOT EXISTS `mod_titan_rune_pending_rewards` (
  `instance_id` INT UNSIGNED NOT NULL,
  `boss_entry` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `guid` INT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  `count` INT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`instance_id`,`boss_entry`,`mode`,`guid`,`item_entry`),
  KEY `idx_titan_pending_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
