CREATE TABLE IF NOT EXISTS `mod_titan_rune_instance` (
  `map_id` INT UNSIGNED NOT NULL,
  `instance_id` INT UNSIGNED NOT NULL,
  `protocol` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `activated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`map_id`,`instance_id`),
  KEY `idx_protocol_time` (`protocol`,`activated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
