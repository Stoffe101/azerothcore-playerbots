CREATE TABLE IF NOT EXISTS `mod_admin_panel_settings` (
  `setting_key` VARCHAR(32) NOT NULL,
  `setting_value` VARCHAR(64) NOT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_admin_panel_locations` (
  `account_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(24) NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `position_x` FLOAT NOT NULL,
  `position_y` FLOAT NOT NULL,
  `position_z` FLOAT NOT NULL,
  `orientation` FLOAT NOT NULL,
  PRIMARY KEY (`account_id`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
