-- Safe on fresh, existing and partially migrated installations (MySQL 8.4).
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='shared_minutes');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN shared_minutes INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='boss_kills');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN boss_kills INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='shared_deaths');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN shared_deaths INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='wipes');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN wipes INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='loot_moments');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN loot_moments INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='duels');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN duels INT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='guild_loyalty');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN guild_loyalty SMALLINT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
SET @guild_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_ai_guild_relationship' AND COLUMN_NAME='rivalry');
SET @guild_column_sql := IF(@guild_column_exists=0,
  'ALTER TABLE mod_ai_guild_relationship ADD COLUMN rivalry SMALLINT UNSIGNED NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE guild_column_stmt FROM @guild_column_sql;
EXECUTE guild_column_stmt;
DEALLOCATE PREPARE guild_column_stmt;
