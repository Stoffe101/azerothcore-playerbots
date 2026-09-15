-- The initial AdventureStart rollout used entry-level TBC blues for its spec-aware set.
-- Re-offer that one-time equipment pass after upgrading the profile to late-Vanilla raider epics.
-- The normal AdventureStart persistence immediately marks it granted again after the replacement.
UPDATE `mod_adventure_progression`
SET `starter_gear_granted` = 0,
    `starter_spec_tab` = 255
WHERE `starter_initialized` = 1;
