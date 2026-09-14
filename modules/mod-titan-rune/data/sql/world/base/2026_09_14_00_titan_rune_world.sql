-- Defense Protocol Alpha/Beta/Gamma backport for the 3.3.5a client.
-- Later Wrath Classic currencies are represented as ordinary server items so no custom client DBC
-- is required. Exchange prices are enforced by C++ gossip scripts, not npc_vendor ExtendedCost.

DELETE FROM `item_template` WHERE `entry` IN (900001,900002,900003);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_item`;
CREATE TEMPORARY TABLE `tmp_titan_item` LIKE `item_template`;

INSERT INTO `tmp_titan_item` SELECT * FROM `item_template` WHERE `entry`=45624 LIMIT 1;
UPDATE `tmp_titan_item` SET
  `entry`=900001, `name`='Sidereal Essence', `Quality`=3, `maxcount`=0, `stackable`=200,
  `bonding`=0, `SellPrice`=0, `BuyPrice`=0,
  `description`='Recovered from Defense Protocol Beta. Animated Constellations exchange these for Ulduar rewards.',
  `ScriptName`='', `VerifiedBuild`=NULL;
INSERT INTO `item_template` SELECT * FROM `tmp_titan_item`;
TRUNCATE TABLE `tmp_titan_item`;

INSERT INTO `tmp_titan_item` SELECT * FROM `item_template` WHERE `entry`=45624 LIMIT 1;
UPDATE `tmp_titan_item` SET
  `entry`=900002, `name`='Defiler''s Scourgestone', `Quality`=4, `maxcount`=0, `stackable`=200,
  `bonding`=0, `SellPrice`=0, `BuyPrice`=0,
  `description`='Recovered from Defense Protocol Gamma. Exchange these in Dalaran for raid catch-up rewards.',
  `ScriptName`='', `VerifiedBuild`=NULL;
INSERT INTO `item_template` SELECT * FROM `tmp_titan_item`;
TRUNCATE TABLE `tmp_titan_item`;

INSERT INTO `tmp_titan_item` SELECT * FROM `item_template` WHERE `entry`=41119 LIMIT 1;
UPDATE `tmp_titan_item` SET
  `entry`=900003, `name`='Holy Hand Grenade', `Quality`=2, `maxcount`=0, `stackable`=20,
  `bonding`=1, `SellPrice`=0, `BuyPrice`=0, `spellid_1`=0, `spelltrigger_1`=0,
  `description`='Protocol supply. Use near a Zombie Horror during Beta/Gamma Plague Rune dungeons.',
  `ScriptName`='item_titan_rune_grenade', `VerifiedBuild`=NULL;
INSERT INTO `item_template` SELECT * FROM `tmp_titan_item`;
DROP TEMPORARY TABLE `tmp_titan_item`;

-- Custom creature templates. Clone native 3.3.5 creatures so every model/display is already in
-- the stock client, then replace names, factions, script binding and combat characteristics.
DELETE FROM `creature_template` WHERE `entry` BETWEEN 900100 AND 900112;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_creature`;
CREATE TEMPORARY TABLE `tmp_titan_creature` LIKE `creature_template`;

-- Selector device (Scourge Cauldron model, neutral/non-combat).
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=11152 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900100,`name`='Mysterious Titan Device',`subname`='Defense Protocol Control',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_device',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Gamma Warden/support selector.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=32172 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900101,`name`='Defense Protocol Warden',`subname`='Gamma Support',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_warden',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Blood Rune Witch Doctor brew cauldron.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=11152 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900102,`name`='Witch Doctor''s Cauldron',`subname`='Blood Rune Countermeasure',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_cauldron',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Arcane mirrors use the native Underbelly mirror human model.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=31879 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900103,`name`='Mirror Image',`subname`='Arcane Caster',`minlevel`=80,`maxlevel`=80,
 `faction`=14,`npcflag`=0,`unit_flags`=0,`AIName`='',`ScriptName`='npc_titan_rune_helper',`HealthModifier`=0.50,`DamageModifier`=1.0,`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=900103 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900104,`subname`='Arcane Melee';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=900103 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900105,`subname`='Arcane Healer';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Zombie Horror.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=38104 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900106,`name`='Zombie Horror',`subname`='Defense Protocol Plague',`minlevel`=80,`maxlevel`=80,
 `faction`=14,`npcflag`=0,`unit_flags`=0,`AIName`='',`ScriptName`='npc_titan_rune_helper',`HealthModifier`=8.0,`DamageModifier`=1.0,`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Titan Immortal Crusher uses the native Ulduar Crusher Tentacle model but our isolated AI.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=33966 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900107,`difficulty_entry_1`=0,`name`='Immortal Crusher Tentacle',`subname`='Defense Protocol Titan',
 `minlevel`=80,`maxlevel`=80,`faction`=14,`npcflag`=0,`unit_flags`=0,`AIName`='',`ScriptName`='npc_titan_rune_helper',
 `HealthModifier`=15.0,`DamageModifier`=1.0,`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;

-- Dalaran exchange NPCs.
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=32172 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900110,`name`='Animated Constellation',`subname`='Sidereal Essence Exchange',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_exchange',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=32172 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900111,`name`='Korralin Hoperender',`subname`='Defiler''s Scourgestone Exchange',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_exchange',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`; TRUNCATE TABLE `tmp_titan_creature`;
INSERT INTO `tmp_titan_creature` SELECT * FROM `creature_template` WHERE `entry`=28701 LIMIT 1;
UPDATE `tmp_titan_creature` SET `entry`=900112,`name`='Kolara Dreamsmasher',`subname`='Defiler''s Scourgestone Exchange',
 `minlevel`=80,`maxlevel`=80,`faction`=35,`npcflag`=1,`AIName`='',`ScriptName`='npc_titan_rune_exchange',`VerifiedBuild`=NULL;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_creature`;
DROP TEMPORARY TABLE `tmp_titan_creature`;

-- Client-native model mappings for the custom template IDs.
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 900100 AND 900112;
INSERT INTO `creature_template_model` SELECT 900100,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=11152;
INSERT INTO `creature_template_model` SELECT 900101,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=32172;
INSERT INTO `creature_template_model` SELECT 900102,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=11152;
INSERT INTO `creature_template_model` SELECT 900103,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=31879;
INSERT INTO `creature_template_model` SELECT 900104,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=31879;
INSERT INTO `creature_template_model` SELECT 900105,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=31879;
INSERT INTO `creature_template_model` SELECT 900106,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=38104;
INSERT INTO `creature_template_model` SELECT 900107,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=33966;
INSERT INTO `creature_template_model` SELECT 900110,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=32172;
INSERT INTO `creature_template_model` SELECT 900111,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=32172;
INSERT INTO `creature_template_model` SELECT 900112,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,NULL FROM `creature_template_model` WHERE `CreatureID`=28701;

-- Permanent exchanges in Dalaran. Coordinates are based on native Dalaran NPC spawn points:
-- Alliance near Amisi Azuregaze, Horde near Ajay Green, and a neutral copy in the commerce area.
DELETE FROM `creature` WHERE `guid` BETWEEN 900110 AND 900114;
INSERT INTO `creature` (`guid`,`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`dynamicflags`,`ScriptNameOverride`,`VerifiedBuild`,`CreateObject`,`Comment`) VALUES
(900110,900110,571,0,0,1,1,0,5874.0,716.0,643.18,2.3,300,0,0,1,0,0,0,0,0,'',NULL,0,'Titan Rune Sidereal Exchange - neutral'),
(900111,900110,571,0,0,1,1,0,5849.5,637.0,647.57,1.0,300,0,0,1,0,0,0,0,0,'',NULL,0,'Titan Rune Sidereal Exchange - Alliance'),
(900112,900110,571,0,0,1,1,0,5761.0,718.0,618.64,5.6,300,0,0,1,0,0,0,0,0,'',NULL,0,'Titan Rune Sidereal Exchange - Horde'),
(900113,900111,571,0,0,1,1,0,5852.0,637.0,647.57,1.0,300,0,0,1,0,0,0,0,0,'',NULL,0,'Korralin Hoperender - Alliance Gamma exchange'),
(900114,900112,571,0,0,1,1,0,5763.5,718.0,618.64,5.6,300,0,0,1,0,0,0,0,0,'',NULL,0,'Kolara Dreamsmasher - Horde Gamma exchange');
