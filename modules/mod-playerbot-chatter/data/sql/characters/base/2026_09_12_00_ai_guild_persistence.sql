CREATE TABLE IF NOT EXISTS `mod_ai_guild_profile` (
  `bot_guid` INT UNSIGNED NOT NULL,
  `persona_seed` INT UNSIGNED NOT NULL,
  `temperament` TINYINT UNSIGNED NOT NULL DEFAULT 50,
  `humor` TINYINT UNSIGNED NOT NULL DEFAULT 50,
  `confidence` TINYINT UNSIGNED NOT NULL DEFAULT 50,
  `sociability` TINYINT UNSIGNED NOT NULL DEFAULT 50,
  `preferred_content` VARCHAR(32) NOT NULL DEFAULT 'mixed',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bot_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ai_guild_relationship` (
  `bot_guid` INT UNSIGNED NOT NULL,
  `target_type` TINYINT UNSIGNED NOT NULL COMMENT '0=player,1=bot',
  `target_guid` INT UNSIGNED NOT NULL,
  `familiarity` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `affinity` SMALLINT NOT NULL DEFAULT 0,
  `trust` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `shared_runs` INT UNSIGNED NOT NULL DEFAULT 0,
  `last_interaction` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`bot_guid`,`target_type`,`target_guid`),
  KEY `idx_ai_guild_relationship_target` (`target_type`,`target_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ai_guild_event` (
  `event_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_type` VARCHAR(32) NOT NULL,
  `actor_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `target_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `map_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `encounter_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `summary` VARCHAR(500) NOT NULL DEFAULT '',
  `occurred_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  KEY `idx_ai_guild_event_actor_time` (`actor_guid`,`occurred_at`),
  KEY `idx_ai_guild_event_type_time` (`event_type`,`occurred_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ai_guild_memory` (
  `memory_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `bot_guid` INT UNSIGNED NOT NULL,
  `event_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `memory_type` VARCHAR(32) NOT NULL,
  `importance` TINYINT UNSIGNED NOT NULL DEFAULT 50,
  `related_type` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `related_guid` INT UNSIGNED NOT NULL DEFAULT 0,
  `summary` VARCHAR(500) NOT NULL,
  `occurred_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`memory_id`),
  KEY `idx_ai_guild_memory_bot_importance_time` (`bot_guid`,`importance`,`occurred_at`),
  KEY `idx_ai_guild_memory_related` (`related_type`,`related_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
