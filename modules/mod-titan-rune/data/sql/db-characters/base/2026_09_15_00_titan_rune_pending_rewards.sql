-- Durable per-player Titan Rune reward ledger.
-- Rows are retained after delivery so repeated boss-death callbacks cannot duplicate currency.
CREATE TABLE IF NOT EXISTS `mod_titan_rune_player_rewards` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid` INT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `boss_entry` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  `item_count` INT UNSIGNED NOT NULL DEFAULT 1,
  `reason` VARCHAR(160) NOT NULL DEFAULT 'Titan Rune reward',
  `delivered` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `delivered_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_titan_reward` (`guid`,`instance_id`,`boss_entry`,`mode`,`item_entry`),
  KEY `idx_titan_reward_pending` (`guid`,`delivered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
