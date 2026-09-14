CREATE TABLE IF NOT EXISTS `mod_living_world_meta` (
  `key_name` VARCHAR(64) NOT NULL,
  `value_bigint` BIGINT NOT NULL DEFAULT 0,
  `value_text` VARCHAR(255) NOT NULL DEFAULT '',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`key_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mod_living_world_guild_activity` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guild_id` INT UNSIGNED NOT NULL,
  `actor_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `activity_type` VARCHAR(32) NOT NULL,
  `summary` VARCHAR(500) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_guild_time` (`guild_id`,`created_at`),
  KEY `idx_actor_time` (`actor_guid`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mod_living_world_member` (
  `guid` INT UNSIGNED NOT NULL,
  `guild_id` INT UNSIGNED NOT NULL,
  `attendance_points` INT UNSIGNED NOT NULL DEFAULT 0,
  `helpfulness_points` INT UNSIGNED NOT NULL DEFAULT 0,
  `economy_points` INT UNSIGNED NOT NULL DEFAULT 0,
  `last_active` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  KEY `idx_guild_attendance` (`guild_id`,`attendance_points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mod_living_world_economy_order` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guild_id` INT UNSIGNED NOT NULL,
  `requester_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `item_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `profession_skill` INT UNSIGNED NOT NULL DEFAULT 0,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `fulfilled` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `note` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fulfilled_at` DATETIME NULL,
  PRIMARY KEY (`id`),
  KEY `idx_guild_open` (`guild_id`,`fulfilled`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
