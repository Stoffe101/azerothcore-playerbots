-- Living-guild schedule, attendance and bounded profession economy.
-- The guild-life director only records/announces social goals; it never changes human guild ranks.
CREATE TABLE IF NOT EXISTS `mod_ai_guild_life_day` (
  `guild_id` INT UNSIGNED NOT NULL,
  `activity_date` DATE NOT NULL,
  `focus_type` VARCHAR(24) NOT NULL,
  `title` VARCHAR(80) NOT NULL,
  `summary` VARCHAR(500) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`,`activity_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Persistent daily guild-life focus';

CREATE TABLE IF NOT EXISTS `mod_ai_guild_life_member` (
  `guild_id` INT UNSIGNED NOT NULL,
  `player_guid` INT UNSIGNED NOT NULL,
  `activity_date` DATE NOT NULL,
  `online_minutes` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `recognition_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `noticed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`,`player_guid`,`activity_date`),
  KEY `idx_ai_guild_life_member_day` (`guild_id`,`activity_date`,`online_minutes`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Real-player attendance for guild-life activities';

CREATE TABLE IF NOT EXISTS `mod_ai_guild_profession_day` (
  `guild_id` INT UNSIGNED NOT NULL,
  `activity_date` DATE NOT NULL,
  `contributing_bots` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `profession_kinds` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `contribution_copper` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `credited` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`,`activity_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Bounded daily income from persistent roster-bot professions';
