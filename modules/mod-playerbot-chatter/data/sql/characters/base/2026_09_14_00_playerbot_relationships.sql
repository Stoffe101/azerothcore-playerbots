CREATE TABLE IF NOT EXISTS `mod_playerbot_chatter_relationship` (
    `bot_guid` BIGINT UNSIGNED NOT NULL,
    `subject_guid` BIGINT UNSIGNED NOT NULL,
    `subject_is_bot` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `affinity` INT NOT NULL DEFAULT 0,
    `trust` INT NOT NULL DEFAULT 0,
    `rivalry` INT NOT NULL DEFAULT 0,
    `guild_loyalty` INT NOT NULL DEFAULT 0,
    `shared_minutes` INT UNSIGNED NOT NULL DEFAULT 0,
    `boss_kills` INT UNSIGNED NOT NULL DEFAULT 0,
    `deaths_together` INT UNSIGNED NOT NULL DEFAULT 0,
    `loot_moments` INT UNSIGNED NOT NULL DEFAULT 0,
    `duels` INT UNSIGNED NOT NULL DEFAULT 0,
    `last_event` VARCHAR(255) NOT NULL DEFAULT '',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`bot_guid`, `subject_guid`),
    KEY `idx_subject` (`subject_guid`),
    KEY `idx_affinity` (`bot_guid`, `affinity`),
    KEY `idx_shared` (`bot_guid`, `shared_minutes`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mod_playerbot_chatter_memories` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `bot_guid` BIGINT UNSIGNED NOT NULL,
    `subject_guid` BIGINT UNSIGNED NOT NULL,
    `kind` VARCHAR(32) NOT NULL DEFAULT 'event',
    `importance` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `ts` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `memory_text` VARCHAR(500) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_pair_ts` (`bot_guid`, `subject_guid`, `ts`),
    KEY `idx_pair_importance` (`bot_guid`, `subject_guid`, `importance`, `ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
