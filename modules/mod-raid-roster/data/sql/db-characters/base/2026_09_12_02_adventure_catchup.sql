ALTER TABLE `mod_adventure_controls`
  ADD COLUMN `catchup_claims` BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER `rep_percent`;
