SET @catchup_column_exists := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='mod_adventure_controls' AND COLUMN_NAME='catchup_claims');
SET @catchup_column_sql := IF(@catchup_column_exists=0,
  'ALTER TABLE mod_adventure_controls ADD COLUMN catchup_claims BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER rep_percent', 'SELECT 1');
PREPARE catchup_column_stmt FROM @catchup_column_sql;
EXECUTE catchup_column_stmt;
DEALLOCATE PREPARE catchup_column_stmt;
