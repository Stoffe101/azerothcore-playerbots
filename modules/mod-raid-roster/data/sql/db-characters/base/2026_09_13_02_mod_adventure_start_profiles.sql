-- Existing installs may already have mod_adventure_progression without starter_profile, while
-- fresh/current installs may already include the column from the base CREATE TABLE update.
-- MySQL 8.4 does NOT support `ADD COLUMN IF NOT EXISTS`, so perform an explicit information_schema
-- check and only execute ALTER TABLE when the column is actually missing.

SET @starter_profile_exists := (
    SELECT COUNT(*)
    FROM `INFORMATION_SCHEMA`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE()
      AND `TABLE_NAME` = 'mod_adventure_progression'
      AND `COLUMN_NAME` = 'starter_profile'
);

SET @starter_profile_sql := IF(
    @starter_profile_exists = 0,
    'ALTER TABLE `mod_adventure_progression` ADD COLUMN `starter_profile` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `starter_spec_tab`',
    'SELECT 1'
);

PREPARE starter_profile_stmt FROM @starter_profile_sql;
EXECUTE starter_profile_stmt;
DEALLOCATE PREPARE starter_profile_stmt;
