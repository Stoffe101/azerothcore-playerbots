CREATE TABLE IF NOT EXISTS `mod_ai_guild_economy` (
  `guild_id` INT UNSIGNED NOT NULL,
  `money_copper` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `earned_copper` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `spent_copper` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Persistent AI guild treasury';

CREATE TABLE IF NOT EXISTS `mod_ai_guild_stock` (
  `guild_id` INT UNSIGNED NOT NULL,
  `item_id` INT UNSIGNED NOT NULL,
  `item_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`, `item_id`),
  KEY `idx_ai_guild_stock_item` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Persistent AI guild virtual vault stock';

CREATE TABLE IF NOT EXISTS `mod_ai_guild_request` (
  `request_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guild_id` INT UNSIGNED NOT NULL,
  `requester_guid` INT UNSIGNED NOT NULL,
  `target_guid` INT UNSIGNED NOT NULL,
  `request_type` VARCHAR(16) NOT NULL,
  `item_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `item_count` INT UNSIGNED NOT NULL DEFAULT 1,
  `quoted_copper` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `status` VARCHAR(16) NOT NULL DEFAULT 'queued',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fulfilled_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`request_id`),
  KEY `idx_ai_guild_request_queue` (`guild_id`, `status`, `request_id`),
  KEY `idx_ai_guild_request_requester` (`requester_guid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Persistent AI guild craft, shopping and delivery requests';
