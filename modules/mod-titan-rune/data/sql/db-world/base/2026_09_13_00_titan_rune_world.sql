-- Titan Rune dungeon support for the 3.3.5a server.
-- Classic-only currencies are represented as server-side custom items cloned from Emblem of Triumph.
-- The exchange NPCs are scripted gossip vendors, so no custom client DBC/extended-cost rows are required.

CREATE TABLE IF NOT EXISTS `mod_titan_rune_vendor_items` (
  `vendor` TINYINT UNSIGNED NOT NULL COMMENT '1=Sidereal Essence, 2=Defiler Scourgestone',
  `item_entry` INT UNSIGNED NOT NULL,
  `cost` SMALLINT UNSIGNED NOT NULL,
  `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`vendor`,`item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_titan_rune_vendor_spawns` (
  `entry` INT UNSIGNED NOT NULL,
  `spawn_guid` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Custom currency items. Clone an existing emblem so all 3.3.5 client-facing item fields remain valid.
DELETE FROM `item_template` WHERE `entry` IN (900100,900101);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_item`;
CREATE TEMPORARY TABLE `tmp_titan_item` LIKE `item_template`;
INSERT INTO `tmp_titan_item` SELECT * FROM `item_template` WHERE `entry`=47241 LIMIT 1;
UPDATE `tmp_titan_item`
SET `entry`=900100,
    `name`='Sidereal Essence',
    `description`='A concentrated fragment of titan energy earned from Defense Protocol Beta.';
INSERT INTO `item_template` SELECT * FROM `tmp_titan_item`;
TRUNCATE TABLE `tmp_titan_item`;
INSERT INTO `tmp_titan_item` SELECT * FROM `item_template` WHERE `entry`=47241 LIMIT 1;
UPDATE `tmp_titan_item`
SET `entry`=900101,
    `name`='Defiler''s Scourgestone',
    `description`='A corrupted scourgestone earned from bosses under Defense Protocol Gamma.';
INSERT INTO `item_template` SELECT * FROM `tmp_titan_item`;
DROP TEMPORARY TABLE `tmp_titan_item`;

-- Scripted NPC templates. Clone a stock creature row/model so the custom NPCs need no client patch.
DELETE FROM `creature_template` WHERE `entry` IN (900110,900111,900112);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_creature`;
CREATE TEMPORARY TABLE `tmp_titan_creature` LIKE `creature_template`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=68 LIMIT 1;
UPDATE `tmp_titan_creature`
SET `entry`=900110, `name`='Titan Rune Coordinator', `subname`='<Defense Protocols>',
    `minlevel`=80, `maxlevel`=80, `faction`=35, `npcflag`=1, `ScriptName`='npc_titan_rune_coordinator';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`;
TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=68 LIMIT 1;
UPDATE `tmp_titan_creature`
SET `entry`=900111, `name`='Animated Constellation', `subname`='<Sidereal Essence Exchange>',
    `minlevel`=80, `maxlevel`=80, `faction`=35, `npcflag`=1, `ScriptName`='npc_titan_sidereal_vendor';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`;
TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=68 LIMIT 1;
UPDATE `tmp_titan_creature`
SET `entry`=900112, `name`='Titan Rune Quartermaster', `subname`='<Defiler''s Scourgestone Exchange>',
    `minlevel`=80, `maxlevel`=80, `faction`=35, `npcflag`=1, `ScriptName`='npc_titan_scourgestone_vendor';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`;
DROP TEMPORARY TABLE `tmp_titan_creature`;

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (900110,900111,900112);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_model`;
CREATE TEMPORARY TABLE `tmp_titan_model` LIKE `creature_template_model`;
INSERT INTO `tmp_titan_model` SELECT * FROM `creature_template_model` WHERE `CreatureID`=68;
UPDATE `tmp_titan_model` SET `CreatureID`=900110;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_model`;
TRUNCATE TABLE `tmp_titan_model`;
INSERT INTO `tmp_titan_model` SELECT * FROM `creature_template_model` WHERE `CreatureID`=68;
UPDATE `tmp_titan_model` SET `CreatureID`=900111;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_model`;
TRUNCATE TABLE `tmp_titan_model`;
INSERT INTO `tmp_titan_model` SELECT * FROM `creature_template_model` WHERE `CreatureID`=68;
UPDATE `tmp_titan_model` SET `CreatureID`=900112;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_model`;
DROP TEMPORARY TABLE `tmp_titan_model`;

-- Rebuild the catalogs idempotently. Names are resolved against the stock 3.3.5 item DB so the
-- module does not hard-code item IDs that can vary across data revisions.
DELETE FROM `mod_titan_rune_vendor_items`;

-- Animated Constellation: Ulduar 10 hard-mode style rewards for Sidereal Essence.
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,10 FROM item_template WHERE name='Aesir''s Edge' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,20 FROM item_template WHERE name='Icecore Staff' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,30 FROM item_template WHERE name='Hammer of Crushing Whispers' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,40 FROM item_template WHERE name='Magnetized Projectile Emitter' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,50 FROM item_template WHERE name='Fusion Blade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,60 FROM item_template WHERE name='Aesuga, Hand of the Ardent Champion' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,32,70 FROM item_template WHERE name='Breastplate of the Timeless' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,32,80 FROM item_template WHERE name='Zodiac Leggings' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,90 FROM item_template WHERE name='The Masticator' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,100 FROM item_template WHERE name='Perilous Bite' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,110 FROM item_template WHERE name='Shiver' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,120 FROM item_template WHERE name='The Boreal Guard' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,130 FROM item_template WHERE name='Ice Layered Barrier' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,140 FROM item_template WHERE name='Combatant''s Bootblade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,150 FROM item_template WHERE name='Caress of Insanity' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,160 FROM item_template WHERE name='Gilded Steel Legplates' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,170 FROM item_template WHERE name='Breastplate of the Stoneshaper' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,180 FROM item_template WHERE name='Fused Alloy Legplates' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,190 FROM item_template WHERE name='Mimiron''s Flight Goggles' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,200 FROM item_template WHERE name='Dark Matter' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,210 FROM item_template WHERE name='Starfall Girdle' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,220 FROM item_template WHERE name='Meteorite Crystal' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,230 FROM item_template WHERE name='Sif''s Remembrance' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,240 FROM item_template WHERE name='Mjolnir Runestone' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,250 FROM item_template WHERE name='Strength of the Heavens' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,260 FROM item_template WHERE name='Nebula Band' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,270 FROM item_template WHERE name='Pendant of the Somber Witness' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,280 FROM item_template WHERE name='Band of Lights' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,290 FROM item_template WHERE name='Petrified Ivy Sprig' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,300 FROM item_template WHERE name='Twirling Blades' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,310 FROM item_template WHERE name='Shimmering Seal' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,320 FROM item_template WHERE name='Watchful Eye of Fate' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,330 FROM item_template WHERE name='Loop of the Agile' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,340 FROM item_template WHERE name='Seal of Ulduar' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,350 FROM item_template WHERE name='Bitter Cold Armguards' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,360 FROM item_template WHERE name='Pendant of the Shallow Grave' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,370 FROM item_template WHERE name='Drape of the Faceless General' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,3,380 FROM item_template WHERE name='Crusader Orb' LIMIT 1;

-- Gamma exchange: high-value Trial of the Crusader 25 / Ulduar rewards for Scourgestones.
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,10 FROM item_template WHERE name='Justicebringer' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,20 FROM item_template WHERE name='Archon Glaive' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,30 FROM item_template WHERE name='Death''s Head Crossbow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,40 FROM item_template WHERE name='Dual-blade Butcher' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,50 FROM item_template WHERE name='Twin''s Pact' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,60 FROM item_template WHERE name='Hellion Glaive' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,70 FROM item_template WHERE name='Flare of the Heavens' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,80 FROM item_template WHERE name='Comet''s Trail' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,90 FROM item_template WHERE name='Bastion of Purity' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,100 FROM item_template WHERE name='Bastion of Resolve' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,110 FROM item_template WHERE name='Death''s Verdict' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,120 FROM item_template WHERE name='Death''s Choice' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,130 FROM item_template WHERE name='Reign of the Unliving' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,140 FROM item_template WHERE name='Reign of the Dead' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,150 FROM item_template WHERE name='Solace of the Defeated' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,160 FROM item_template WHERE name='Solace of the Fallen' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,170 FROM item_template WHERE name='Satrina''s Impeding Scarab' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,180 FROM item_template WHERE name='Juggernaut''s Vitality' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,190 FROM item_template WHERE name='Belt of Deathly Dominion' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,200 FROM item_template WHERE name='Belt of the Forgotten Martyr' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,210 FROM item_template WHERE name='Belt of the Ice Burrower' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,220 FROM item_template WHERE name='Belt of the Merciless Killer' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,230 FROM item_template WHERE name='Armbands of the Ashen Saint' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,240 FROM item_template WHERE name='Band of Deplorable Violence' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,250 FROM item_template WHERE name='Band of the Violent Temperment' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,260 FROM item_template WHERE name='Armbands of Dark Determination' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,270 FROM item_template WHERE name='Armguards of the Shieldmaiden' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,280 FROM item_template WHERE name='Band of Callous Aggression' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,290 FROM item_template WHERE name='Band of the Traitor King' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,20,300 FROM item_template WHERE name='Trophy of the Crusade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,12,310 FROM item_template WHERE name='Primordial Saronite' LIMIT 1;
