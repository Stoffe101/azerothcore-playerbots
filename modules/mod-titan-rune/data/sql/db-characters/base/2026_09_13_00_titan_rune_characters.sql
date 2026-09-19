CREATE TABLE IF NOT EXISTS `mod_titan_rune_selection` (
  `guid` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=off,1=alpha,2=beta,3=gamma',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_titan_rune_boss_rewards` (
  `instance_id` INT UNSIGNED NOT NULL,
  `boss_entry` INT UNSIGNED NOT NULL,
  `mode` TINYINT UNSIGNED NOT NULL,
  `rewarded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`instance_id`,`boss_entry`,`mode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
