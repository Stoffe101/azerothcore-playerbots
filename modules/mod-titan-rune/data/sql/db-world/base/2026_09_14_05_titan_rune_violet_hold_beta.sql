-- Defense Protocol Beta/Gamma uses the same Ulduar-10 catch-up pool for the six random
-- Violet Hold lieutenants. Keep this as a small idempotent follow-up so existing installs that
-- already imported the main protocol-loot table receive the missing rows on the next DB pass.

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_vh_beta_bosses`;
CREATE TEMPORARY TABLE `tmp_titan_vh_beta_bosses` (
  `source_name` VARCHAR(120) NOT NULL PRIMARY KEY
) ENGINE=Memory DEFAULT CHARSET=utf8mb4;

INSERT INTO `tmp_titan_vh_beta_bosses` VALUES
('Erekem'),
('Moragg'),
('Ichoron'),
('Xevozz'),
('Lavanthor'),
('Zuramat the Obliterator');

INSERT IGNORE INTO `mod_titan_rune_boss_loot` (`source_name`,`pool`,`item_entry`)
SELECT b.`source_name`, 3, i.`entry`
FROM `tmp_titan_vh_beta_bosses` b
JOIN `item_template` i ON i.`name` IN (
  'Ironbark Faceguard',
  'Tunic of the Limber Stalker',
  'Lifespark Visage',
  'Might of the Leviathan',
  'Kinetic Ripper'
);

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_vh_beta_bosses`;
