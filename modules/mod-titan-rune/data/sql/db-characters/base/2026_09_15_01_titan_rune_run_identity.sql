-- Persist protocol choices through map unload/restart. A reused instance ID belongs to a new
-- heroic run after its reset deadline, so historical currency rows must not suppress new rewards.
CREATE TABLE IF NOT EXISTS `mod_titan_rune_instances` (
  `instance_id` INT UNSIGNED NOT NULL,
  `map_id` INT UNSIGNED NOT NULL,
  `reset_time` BIGINT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (`instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET @titan_reset_column := (SELECT COUNT(*) FROM `INFORMATION_SCHEMA`.`COLUMNS`
  WHERE `TABLE_SCHEMA`=DATABASE() AND `TABLE_NAME`='mod_titan_rune_player_rewards' AND `COLUMN_NAME`='reset_time');
SET @titan_reset_sql := IF(@titan_reset_column=0,
  'ALTER TABLE `mod_titan_rune_player_rewards` ADD COLUMN `reset_time` BIGINT UNSIGNED NOT NULL DEFAULT 0, DROP INDEX `uq_titan_reward`, ADD UNIQUE KEY `uq_titan_reward` (`guid`,`instance_id`,`boss_entry`,`mode`,`item_entry`,`reset_time`)',
  'SELECT 1');
PREPARE titan_reset_stmt FROM @titan_reset_sql;
EXECUTE titan_reset_stmt;
DEALLOCATE PREPARE titan_reset_stmt;
