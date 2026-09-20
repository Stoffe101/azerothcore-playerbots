-- Add stable Group Composer activity IDs to progression history without breaking existing realms.
-- MySQL 8.4 does not support ADD COLUMN IF NOT EXISTS, so use explicit information_schema guards.

SET @event_activity_id_exists := (
    SELECT COUNT(*)
    FROM `INFORMATION_SCHEMA`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'mod_adventure_progression_event'
      AND `COLUMN_NAME` = 'activity_id'
);

SET @event_activity_id_sql := IF(
    @event_activity_id_exists = 0,
    'ALTER TABLE `mod_adventure_progression_event` ADD COLUMN `activity_id` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `creature_entry`',
    'SELECT 1'
);

PREPARE event_activity_id_stmt FROM @event_activity_id_sql;
EXECUTE event_activity_id_stmt;
DEALLOCATE PREPARE event_activity_id_stmt;

SET @event_activity_id_index_exists := (
    SELECT COUNT(*)
    FROM `INFORMATION_SCHEMA`.`STATISTICS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'mod_adventure_progression_event'
      AND `INDEX_NAME` = 'idx_activity_id_time'
);

SET @event_activity_id_index_sql := IF(
    @event_activity_id_index_exists = 0,
    'ALTER TABLE `mod_adventure_progression_event` ADD KEY `idx_activity_id_time` (`activity_id`, `killed_at`)',
    'SELECT 1'
);

PREPARE event_activity_id_index_stmt FROM @event_activity_id_index_sql;
EXECUTE event_activity_id_index_stmt;
DEALLOCATE PREPARE event_activity_id_index_stmt;

SET @history_activity_id_exists := (
    SELECT COUNT(*)
    FROM `INFORMATION_SCHEMA`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'mod_adventure_progression_history'
      AND `COLUMN_NAME` = 'activity_id'
);

SET @history_activity_id_sql := IF(
    @history_activity_id_exists = 0,
    'ALTER TABLE `mod_adventure_progression_history` ADD COLUMN `activity_id` VARCHAR(64) NOT NULL DEFAULT '''' AFTER `creature_entry`',
    'SELECT 1'
);

PREPARE history_activity_id_stmt FROM @history_activity_id_sql;
EXECUTE history_activity_id_stmt;
DEALLOCATE PREPARE history_activity_id_stmt;

SET @history_activity_id_index_exists := (
    SELECT COUNT(*)
    FROM `INFORMATION_SCHEMA`.`STATISTICS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'mod_adventure_progression_history'
      AND `INDEX_NAME` = 'idx_activity_id'
);

SET @history_activity_id_index_sql := IF(
    @history_activity_id_index_exists = 0,
    'ALTER TABLE `mod_adventure_progression_history` ADD KEY `idx_activity_id` (`activity_id`)',
    'SELECT 1'
);

PREPARE history_activity_id_index_stmt FROM @history_activity_id_index_sql;
EXECUTE history_activity_id_index_stmt;
DEALLOCATE PREPARE history_activity_id_index_stmt;
