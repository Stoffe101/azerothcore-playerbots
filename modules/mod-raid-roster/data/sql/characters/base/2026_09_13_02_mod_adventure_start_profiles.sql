-- Existing installs already imported 2026_09_13_00 before starter profiles existed.
-- MySQL 8.4 supports ADD COLUMN IF NOT EXISTS, making this safe on both upgraded and fresh DBs.
ALTER TABLE `mod_adventure_progression`
  ADD COLUMN IF NOT EXISTS `starter_profile` TINYINT UNSIGNED NOT NULL DEFAULT 0
  AFTER `starter_spec_tab`;
