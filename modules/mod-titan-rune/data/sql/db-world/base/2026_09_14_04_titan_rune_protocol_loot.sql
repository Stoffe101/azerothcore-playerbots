-- Wrath Classic Titan Rune dungeon boss-loot backport for the 3.3.5a client/server base.
-- pool: 1=Alpha raid gear, 2=Alpha Tier 7 token, 3=Beta/Ulduar-10 gear, 4=Beta Tier 8 token.
-- Gamma deliberately reuses the Beta+Alpha pools in code and adds Defiler's Scourgestones separately.
-- Item names are resolved against the stock AzerothCore item_template so this remains compatible with
-- the native 3.3.5 item IDs and requires no client DBC patch.

CREATE TABLE IF NOT EXISTS `mod_titan_rune_boss_loot` (
  `source_name` VARCHAR(120) NOT NULL,
  `pool` TINYINT UNSIGNED NOT NULL,
  `item_entry` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`source_name`,`pool`,`item_entry`),
  KEY `idx_titan_rune_boss_loot_source` (`source_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `mod_titan_rune_boss_loot`;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_loot_names`;
CREATE TEMPORARY TABLE `tmp_titan_rune_loot_names` (
  `source_name` VARCHAR(120) NOT NULL,
  `pool` TINYINT UNSIGNED NOT NULL,
  `item_name` VARCHAR(160) NOT NULL
) ENGINE=Memory DEFAULT CHARSET=utf8mb4;

-- ============================================================================
-- Utgarde Keep
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Prince Keleseth',1,'Girdle of the Ascended Phantom'),
('Prince Keleseth',1,'Spectral Rider''s Girdle'),
('Prince Keleseth',1,'Veiled Amulet of Life'),
('Prince Keleseth',3,'Belt of the Iron Servant'),
('Prince Keleseth',3,'Boots of the Petrified Forest'),
('Skarvald the Constructor',1,'Leggings of the Instructor'),
('Skarvald the Constructor',1,'Slayer of the Lifeless'),
('Skarvald the Constructor',1,'Sabatons of Deathlike Gloom'),
('Skarvald the Constructor',3,'Circlet of True Sight'),
('Skarvald the Constructor',3,'Cloak of the Iron Council'),
('Ingvar the Plunderer',1,'Footsteps of Malygos'),
('Ingvar the Plunderer',1,'Surge Needle Ring'),
('Ingvar the Plunderer',1,'The Soulblade'),
('Ingvar the Plunderer',3,'Greaves of Iron Intensity'),
('Ingvar the Plunderer',3,'Lady Maye''s Sapphire Ring'),
('Ingvar the Plunderer',3,'Leggings of Swift Reflexes');

-- ============================================================================
-- Utgarde Pinnacle
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Svala Sorrowgrave',1,'Accursed Bow of the Elite'),
('Svala Sorrowgrave',1,'Girdle of Lenience'),
('Svala Sorrowgrave',1,'Rapid Attack Gloves'),
('Svala Sorrowgrave',3,'Runetouch Wristwraps'),
('Svala Sorrowgrave',3,'Rune-Etched Nightblade'),
('Gortok Palehoof',1,'Miasma Mantle'),
('Gortok Palehoof',1,'Waistguard of the Tutor'),
('Gortok Palehoof',1,'Cowl of Sheet Lightning'),
('Gortok Palehoof',3,'Archaedas'' Lost Legplates'),
('Gortok Palehoof',3,'Stormtip'),
('Skadi the Ruthless',1,'Arc-Scorched Helmet'),
('Skadi the Ruthless',1,'Cloak of Darkening'),
('Skadi the Ruthless',1,'Chain of Latent Energies'),
('Skadi the Ruthless',3,'Chestplate of Titanic Fury'),
('Skadi the Ruthless',3,'Cover of the Keepers'),
('King Ymiron',1,'Gem of Imprisoned Vassals'),
('King Ymiron',1,'Hammer of the Astral Plane'),
('King Ymiron',1,'Rusted-Link Spiked Gauntlets'),
('King Ymiron',3,'Nimble Climber''s Belt'),
('King Ymiron',3,'Ironaya''s Discarded Mantle'),
('King Ymiron',3,'Elemental Focus Stone');

-- ============================================================================
-- Azjol-Nerub
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Krik''thir the Gatewatcher',1,'Loatheb''s Shadow'),
('Krik''thir the Gatewatcher',1,'Abomination Shoulderblades'),
('Krik''thir the Gatewatcher',1,'Fungi-Stained Coverings'),
('Krik''thir the Gatewatcher',3,'Cowl of Icy Breaths'),
('Krik''thir the Gatewatcher',3,'Signet of Winter'),
('Hadronox',1,'Sulfur Stave'),
('Hadronox',1,'Preceptor''s Bindings'),
('Hadronox',1,'Tainted Girdle of Mending'),
('Hadronox',3,'Armbraces of the Vibrant Flame'),
('Hadronox',3,'Stormedge'),
('Anub''arak',1,'Nerubian Conquerer'),
('Anub''arak',1,'Belabored Legplates'),
('Anub''arak',1,'Cloak of the Dying'),
('Anub''arak',3,'Drape of Fuming Anger'),
('Anub''arak',3,'Furnace Stone'),
('Anub''arak',3,'Gloves of Smoldering Touch');

-- ============================================================================
-- Ahn'kahet: The Old Kingdom
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Elder Nadox',1,'Shoulderplates of Bloodshed'),
('Elder Nadox',1,'Staff of the Plague Beast'),
('Elder Nadox',1,'Dissevered Leggings'),
('Elder Nadox',3,'Gauntlets of the Iron Furnace'),
('Elder Nadox',3,'Igniter Rod'),
('Prince Taldaram',1,'Cuffs of Dark Shadows'),
('Prince Taldaram',1,'Helm of the Corrupted Mind'),
('Prince Taldaram',1,'Necrogenic Belt'),
('Prince Taldaram',3,'Leggings of the Insatiable'),
('Prince Taldaram',3,'Pauldrons of Tempered Will'),
('Amanitar',1,'Cuffs of Dark Shadows'),
('Amanitar',1,'Helm of the Corrupted Mind'),
('Amanitar',1,'Necrogenic Belt'),
('Amanitar',3,'Rifle of the Platinum Guard'),
('Amanitar',3,'Shawl of the Caretaker'),
('Jedoga Shadowseeker',1,'Amulet of Autopsy'),
('Jedoga Shadowseeker',1,'Ring of Holy Cleansing'),
('Jedoga Shadowseeker',1,'Legplates of Inescapable Death'),
('Jedoga Shadowseeker',3,'Emerald Signet Ring'),
('Jedoga Shadowseeker',3,'Greaves of the Earthbinder'),
('Herald Volazj',1,'Chestguard of Flagrant Prowess'),
('Herald Volazj',1,'Death''s Bite'),
('Herald Volazj',1,'Necklace of the Glittering Chamber'),
('Herald Volazj',3,'Mark of the Unyielding'),
('Herald Volazj',3,'Shawl of the Shattered Giant'),
('Herald Volazj',3,'Pendant of the Piercing Glare');

-- ============================================================================
-- Drak'Tharon Keep
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Trollgore',1,'Dark Shroud of the Scourge'),
('Trollgore',1,'Demise'),
('Trollgore',1,'Robes of Hoarse Breaths'),
('Trollgore',3,'Sabatons of the Iron Watcher'),
('Trollgore',3,'Shoulderguards of the Solemn Watch'),
('Novos the Summoner',1,'Ring of the Fated'),
('Novos the Summoner',1,'Trespasser''s Boots'),
('Novos the Summoner',1,'Spaulders of Resumed Battle'),
('Novos the Summoner',3,'Helm of Veiled Energies'),
('Novos the Summoner',3,'Spark of Hope'),
('King Dred',1,'Chestplate of the Risen Soldier'),
('King Dred',1,'Noth''s Curse'),
('King Dred',1,'Handgrips of the Foredoomed'),
('King Dred',3,'Cable of the Metrognome'),
('King Dred',3,'Stoneguard'),
('The Prophet Tharon''ja',1,'Enamored Cowl'),
('The Prophet Tharon''ja',1,'Kel''Thuzad''s Reach'),
('The Prophet Tharon''ja',1,'Sabatons of Firmament'),
('The Prophet Tharon''ja',3,'Band of Draconic Guile'),
('The Prophet Tharon''ja',3,'Pulse Baton'),
('The Prophet Tharon''ja',3,'Shoulderguards of Assimilation');

-- ============================================================================
-- Gundrak
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Slad''ran',1,'Embrace of the Spider'),
('Slad''ran',1,'Plague-Impervious Boots'),
('Slad''ran',1,'Spaulders of the Monstrosity'),
('Slad''ran',3,'Static Charge Handwraps'),
('Slad''ran',3,'Stylish Power Cape'),
('Drakkari Elemental',1,'Aegis of Damnation'),
('Drakkari Elemental',1,'Cloak of Armed Strife'),
('Drakkari Elemental',1,'Leggings of Discord'),
('Drakkari Elemental',3,'Binding of the Dragon Matriarch'),
('Drakkari Elemental',3,'Bracers of the Smothering Inferno'),
('Moorabi',1,'Pendant of Lost Vocations'),
('Moorabi',1,'Web Cocoon Grips'),
('Moorabi',1,'Wraith Spear'),
('Moorabi',3,'Breastplate of the Afterlife'),
('Moorabi',3,'Dragonsteel Faceplate'),
('Eck the Ferocious',1,'Avenging Combat Leggings'),
('Eck the Ferocious',1,'Timeworn Silken Band'),
('Eck the Ferocious',1,'Maexxna''s Femur'),
('Eck the Ferocious',3,'Eye of the Broodmother'),
('Eck the Ferocious',3,'Ironscale Leggings'),
('Gal''darah',1,'Hailstorm'),
('Gal''darah',1,'Putrescent Bands'),
('Gal''darah',1,'Drakescale Collar'),
('Gal''darah',3,'Guise of the Midgard Serpent'),
('Gal''darah',3,'Razorscale Talon'),
('Gal''darah',3,'Stormtempered Girdle');

-- ============================================================================
-- The Nexus. The faction commander encounter has two source names.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Commander Stoutbeard',1,'Charmed Cierge'),
('Commander Stoutbeard',1,'Massive Skeletal Ribcage'),
('Commander Stoutbeard',1,'Resurgent Phantom Bindings'),
('Commander Stoutbeard',3,'Nurturing Touch'),
('Commander Stoutbeard',3,'Mantle of the Preserver'),
('Grand Magus Telestra',1,'Claymore of Ancient Power'),
('Grand Magus Telestra',1,'Spirit-World Glass'),
('Grand Magus Telestra',3,'Raiments of the Corrupted'),
('Grand Magus Telestra',3,'Shieldwall of the Breaker'),
('Anomalus',1,'Circle of Life'),
('Anomalus',1,'Gown of Blaumeux'),
('Anomalus',1,'Tunic of Dislocation'),
('Anomalus',3,'Energy Siphon'),
('Anomalus',3,'Combustion Bracers'),
('Ormorok the Tree-Shaper',1,'Signet of the Malevolent'),
('Ormorok the Tree-Shaper',1,'Thane''s Tainted Greathelm'),
('Ormorok the Tree-Shaper',1,'Heinous Mail Chestguard'),
('Ormorok the Tree-Shaper',3,'Firesoul'),
('Ormorok the Tree-Shaper',3,'Firestrider Chestguard'),
('Keristrasza',1,'Plated Gloves of Relief'),
('Keristrasza',1,'Staff of the Plaguehound'),
('Keristrasza',1,'Torque of the Red Dragonflight'),
('Keristrasza',3,'Pyrite Infuser'),
('Keristrasza',3,'Flamewatch Armguards'),
('Keristrasza',3,'Ironsoul');

-- ============================================================================
-- The Oculus. Ley-Guardian Eregos rewards are generated by Cache of Eregos.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Drakos the Interrogator',1,'Helm of the Vast Legions'),
('Drakos the Interrogator',1,'Cloak of Mastery'),
('Drakos the Interrogator',1,'Leggings of Sapphiron'),
('Drakos the Interrogator',3,'Gauntlets of the Wretched'),
('Drakos the Interrogator',3,'Hoperender'),
('Varos Cloudstrider',1,'Circle of Death'),
('Varos Cloudstrider',1,'Cowl of Winged Fear'),
('Varos Cloudstrider',1,'Helmet of the Inner Sanctum'),
('Varos Cloudstrider',3,'Saronite Animus Cloak'),
('Varos Cloudstrider',3,'Pendant of Endless Despair'),
('Mage-Lord Urom',1,'Helm of the Unsubmissive'),
('Mage-Lord Urom',1,'Scepter of Murmuring Spirits'),
('Mage-Lord Urom',1,'Shroud of the Citadel'),
('Mage-Lord Urom',3,'Underworld Mantle'),
('Mage-Lord Urom',3,'Shadowbite'),
('Cache of Eregos',1,'Chain of the Ancient Wyrm'),
('Cache of Eregos',1,'Drakescale Collar'),
('Cache of Eregos',1,'Pendant of the Dragonsworn'),
('Cache of Eregos',1,'Torque of the Red Dragonflight'),
('Cache of Eregos',1,'Black Ice'),
('Cache of Eregos',1,'Mantle of the Extensive Mind'),
('Cache of Eregos',3,'Vestments of the Piercing Light'),
('Cache of Eregos',3,'Avalanche'),
('Cache of Eregos',3,'Winter''s Frigid Embrace');

-- ============================================================================
-- Halls of Stone. Tribunal loot comes from the Tribunal Chest rather than a boss corpse.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Maiden of Grief',1,'Boots of the Follower'),
('Maiden of Grief',1,'Sash of Mortal Desire'),
('Maiden of Grief',1,'Boots of the Worshiper'),
('Maiden of Grief',3,'Belt of the Blood Pit'),
('Maiden of Grief',3,'Treads of the Invader'),
('Krystallus',1,'Bracers of Lost Sentiments'),
('Krystallus',1,'Watchful Eye'),
('Krystallus',1,'Frostblight Pauldrons'),
('Krystallus',3,'Handwraps of Resonance'),
('Krystallus',3,'Legacy of Thunder'),
('Tribunal Chest',1,'Gauntlets of the Master'),
('Tribunal Chest',1,'Grieving Spellblade'),
('Tribunal Chest',1,'Band of Neglected Pleas'),
('Tribunal Chest',3,'Adamant Handguards'),
('Tribunal Chest',3,'Leggings of Unstable Discharge'),
('Sjonnir The Ironshaper',1,'Greatring of Collision'),
('Sjonnir The Ironshaper',1,'Greatstaff of the Nexus'),
('Sjonnir The Ironshaper',1,'Pendant of the Dragonsworn'),
('Sjonnir The Ironshaper',3,'Bloodcrush Cudgel'),
('Sjonnir The Ironshaper',3,'Boots of Unsettled Prey'),
('Sjonnir The Ironshaper',3,'Bracers of Righteous Reformation');

-- ============================================================================
-- Halls of Lightning
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('General Bjarngrim',1,'Boots of Persistence'),
('General Bjarngrim',1,'Gloves of Dark Gestures'),
('General Bjarngrim',1,'Deflection Band'),
('General Bjarngrim',3,'Cloak of the Dormant Blaze'),
('General Bjarngrim',3,'Drape of the Spellweaver'),
('Volkhan',1,'Chivalric Chestguard'),
('Volkhan',1,'Knife of Incision'),
('Volkhan',1,'Splint-Bound Leggings'),
('Volkhan',3,'Fervor of the Protectorate'),
('Volkhan',3,'Golemheart Longbow'),
('Ionar',1,'Ravaging Sabatons'),
('Ionar',1,'Agonal Sash'),
('Ionar',1,'Collar of Dissolution'),
('Ionar',3,'Treacherous Shoulderpads'),
('Ionar',3,'Iceshear Mantle'),
('Loken',1,'Gown of the Spell-Weaver'),
('Loken',1,'Signet of the Accord'),
('Loken',1,'Ice Spire Scepter'),
('Loken',3,'Armbands of the Construct'),
('Loken',3,'Chestplate of Vicious Potency'),
('Loken',3,'Pillar of Fortitude');

-- ============================================================================
-- The Violet Hold. Every random lieutenant shares the same Beta Ulduar-10 pool.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Erekem',1,'Contagion Gloves'),
('Erekem',1,'Blackened Legplates of Feugen'),
('Erekem',1,'Infection Repulser'),
('Moragg',1,'Repelling Charge'),
('Moragg',1,'Leggings of Innumerable Barbs'),
('Moragg',1,'Retcher''s Shoulderpads'),
('Ichoron',1,'Sullen Cloth Boots'),
('Ichoron',1,'Blistered Belt of Decay'),
('Ichoron',1,'Torment of the Banished'),
('Xevozz',1,'Bands of Anxiety'),
('Xevozz',1,'Handgrips of Turmoil'),
('Xevozz',1,'Drape of Surgery'),
('Lavanthor',1,'Sealing Ring of Grobbulus'),
('Lavanthor',1,'Blade of Dormant Memories'),
('Lavanthor',1,'Iron Rings of Endurance'),
('Zuramat the Obliterator',1,'Hatestrike'),
('Zuramat the Obliterator',1,'The Skull of Ruin'),
('Zuramat the Obliterator',1,'Bone-Linked Amulet'),
('Cyanigosa',1,'Anarchy'),
('Cyanigosa',1,'Focusing Energy Epaulets'),
('Cyanigosa',1,'Wand of the Archlich'),
('Cyanigosa',3,'Bindings of the Depths'),
('Cyanigosa',3,'Choker of the Abyss'),
('Cyanigosa',3,'Darkstone Ring');

-- ============================================================================
-- The Culling of Stratholme. Mal'Ganis loot is in Dark Runed Chest.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Meathook',1,'Volitant Amulet'),
('Meathook',1,'Crimson Steel'),
('Meathook',1,'Gale-Proof Cloak'),
('Meathook',3,'Conductive Cord'),
('Meathook',3,'Mimiron''s Repeater'),
('Salramm the Fleshcrafter',1,'Legguards of Composure'),
('Salramm the Fleshcrafter',1,'Remembrance Girdle'),
('Salramm the Fleshcrafter',1,'Titan''s Outlook'),
('Salramm the Fleshcrafter',3,'Gloves of Taut Grip'),
('Salramm the Fleshcrafter',3,'Spire of Withering Dreams'),
('Chrono-Lord Epoch',1,'Blade-Scarred Tunic'),
('Chrono-Lord Epoch',1,'Majestic Dragon Figurine'),
('Chrono-Lord Epoch',1,'Circle of Arcane Streams'),
('Chrono-Lord Epoch',3,'Plasma Foil'),
('Chrono-Lord Epoch',3,'Power Enhancing Loop'),
('Infinite Corruptor',1,'Omen of Ruin'),
('Infinite Corruptor',1,'The Stray'),
('Infinite Corruptor',1,'Contortion'),
('Infinite Corruptor',1,'Medallion of the Disgraced'),
('Infinite Corruptor',1,'Minion Bracers'),
('Infinite Corruptor',3,'Pulsing Spellshield'),
('Infinite Corruptor',3,'Vest of the Glowing Crescent'),
('Dark Runed Chest',1,'Barricade of Eternity'),
('Dark Runed Chest',1,'Bone-Framed Bracers'),
('Dark Runed Chest',1,'Chain of the Ancient Wyrm'),
('Dark Runed Chest',3,'Abaddon'),
('Dark Runed Chest',3,'Deliverance'),
('Dark Runed Chest',3,'Devotion');

-- ============================================================================
-- Trial of the Champion. Alpha is unavailable here, so only Beta/Gamma rows are supplied.
-- Cache aliases cover the 3.3.5 encounter implementations that award loot through chests.
-- ============================================================================
INSERT INTO `tmp_titan_rune_loot_names` VALUES
('Champion''s Cache',3,'Kingsbane'),
('Champion''s Cache',3,'Faceguard of the Eyeless Horror'),
('Eadric the Pure',3,'Pendant of a Thousand Maws'),
('Eadric the Pure',3,'Relentless Edge'),
('Argent Confessor Paletress',3,'Pendant of a Thousand Maws'),
('Argent Confessor Paletress',3,'Relentless Edge'),
('The Black Knight',3,'Touch of Madness'),
('The Black Knight',3,'Treads of the Dragon Council'),
('The Black Knight',3,'Royal Seal of King Llane');

-- Resolve every gear row by name. Three Phase-1 Naxx items intentionally absent from Blizzard's
-- Titan Rune tables (Saltarello Shoes, Tunic of the Lost Pack, Gauntlets of Combined Strength)
-- are intentionally not present above.
INSERT IGNORE INTO `mod_titan_rune_boss_loot` (`source_name`,`pool`,`item_entry`)
SELECT n.`source_name`, n.`pool`, i.`entry`
FROM `tmp_titan_rune_loot_names` n
JOIN `item_template` i ON i.`name` COLLATE utf8mb4_unicode_ci = n.`item_name` COLLATE utf8mb4_unicode_ci;

-- Faction commander in Nexus uses the same loot pool under either NPC name.
INSERT IGNORE INTO `mod_titan_rune_boss_loot`
SELECT 'Commander Kolurg', `pool`, `item_entry`
FROM `mod_titan_rune_boss_loot` WHERE `source_name`='Commander Stoutbeard';

-- Trial of the Champion may expose the second encounter through cache objects instead of corpses.
INSERT IGNORE INTO `mod_titan_rune_boss_loot`
SELECT 'Eadric''s Cache', `pool`, `item_entry`
FROM `mod_titan_rune_boss_loot` WHERE `source_name`='Eadric the Pure';
INSERT IGNORE INTO `mod_titan_rune_boss_loot`
SELECT 'Confessor''s Cache', `pool`, `item_entry`
FROM `mod_titan_rune_boss_loot` WHERE `source_name`='Argent Confessor Paletress';

-- ============================================================================
-- Final-boss token pools. Alpha uses the nine Helm/Shoulder/Leg Tier 7 tokens. Beta/Gamma use
-- all fifteen Wayward Tier 8 tokens (five armor slots x three class families).
-- ============================================================================
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_alpha_finals`;
CREATE TEMPORARY TABLE `tmp_titan_rune_alpha_finals` (`source_name` VARCHAR(120) NOT NULL PRIMARY KEY) ENGINE=Memory;
INSERT INTO `tmp_titan_rune_alpha_finals` VALUES
('Ingvar the Plunderer'),('King Ymiron'),('Anub''arak'),('Herald Volazj'),('The Prophet Tharon''ja'),
('Gal''darah'),('Keristrasza'),('Cache of Eregos'),('Sjonnir The Ironshaper'),('Loken'),('Cyanigosa'),('Dark Runed Chest');

INSERT IGNORE INTO `mod_titan_rune_boss_loot` (`source_name`,`pool`,`item_entry`)
SELECT f.`source_name`, 2, i.`entry`
FROM `tmp_titan_rune_alpha_finals` f
JOIN `item_template` i ON i.`name` IN (
 'Helm of the Lost Conqueror','Helm of the Lost Protector','Helm of the Lost Vanquisher',
 'Spaulders of the Lost Conqueror','Spaulders of the Lost Protector','Spaulders of the Lost Vanquisher',
 'Leggings of the Lost Conqueror','Leggings of the Lost Protector','Leggings of the Lost Vanquisher'
);

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_beta_finals`;
CREATE TEMPORARY TABLE `tmp_titan_rune_beta_finals` (`source_name` VARCHAR(120) NOT NULL PRIMARY KEY) ENGINE=Memory;
INSERT INTO `tmp_titan_rune_beta_finals` SELECT `source_name` FROM `tmp_titan_rune_alpha_finals`;
INSERT IGNORE INTO `tmp_titan_rune_beta_finals` VALUES ('The Black Knight');

INSERT IGNORE INTO `mod_titan_rune_boss_loot` (`source_name`,`pool`,`item_entry`)
SELECT f.`source_name`, 4, i.`entry`
FROM `tmp_titan_rune_beta_finals` f
JOIN `item_template` i ON i.`name` IN (
 'Chestguard of the Wayward Conqueror','Chestguard of the Wayward Protector','Chestguard of the Wayward Vanquisher',
 'Gloves of the Wayward Conqueror','Gloves of the Wayward Protector','Gloves of the Wayward Vanquisher',
 'Helm of the Wayward Conqueror','Helm of the Wayward Protector','Helm of the Wayward Vanquisher',
 'Leggings of the Wayward Conqueror','Leggings of the Wayward Protector','Leggings of the Wayward Vanquisher',
 'Spaulders of the Wayward Conqueror','Spaulders of the Wayward Protector','Spaulders of the Wayward Vanquisher'
);

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_loot_names`;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_alpha_finals`;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_rune_beta_finals`;
