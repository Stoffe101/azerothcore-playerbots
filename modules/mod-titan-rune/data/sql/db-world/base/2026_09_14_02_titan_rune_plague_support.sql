-- Defense Protocol Beta/Gamma Plague Rune helpers for the 3.3.5 client.
-- The Classic-only Zombie Horror and Holy Hand Grenade cache are represented with stock-renderable templates.

DELETE FROM `creature_template` WHERE `entry` IN (900122,900123);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_plague_creature`;
CREATE TEMPORARY TABLE `tmp_titan_plague_creature` LIKE `creature_template`;

-- Zombie Horror: clone a stock Culling of Stratholme Risen Zombie and make it an elite level-81 enemy.
INSERT INTO `tmp_titan_plague_creature`
SELECT * FROM `creature_template` WHERE `entry`=27737 LIMIT 1;
UPDATE `tmp_titan_plague_creature`
SET `entry`=900122,
    `name`='Zombie Horror',
    `subname`='<Defense Protocol Plague Rune>',
    `minlevel`=81,
    `maxlevel`=81,
    `rank`=1,
    `npcflag`=0,
    `ScriptName`='';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_plague_creature`;

TRUNCATE TABLE `tmp_titan_plague_creature`;
-- Cache NPC: use a stock friendly humanoid model and scripted gossip. Functionally represents the five grenades.
INSERT INTO `tmp_titan_plague_creature`
SELECT * FROM `creature_template` WHERE `entry`=68 LIMIT 1;
UPDATE `tmp_titan_plague_creature`
SET `entry`=900123,
    `name`='Holy Hand Grenade Cache',
    `subname`='<5 charges per dungeon>',
    `minlevel`=80,
    `maxlevel`=80,
    `faction`=35,
    `npcflag`=1,
    `ScriptName`='npc_titan_holy_grenade_cache';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_plague_creature`;
DROP TEMPORARY TABLE `tmp_titan_plague_creature`;

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (900122,900123);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_plague_model`;
CREATE TEMPORARY TABLE `tmp_titan_plague_model` LIKE `creature_template_model`;

INSERT INTO `tmp_titan_plague_model`
SELECT * FROM `creature_template_model` WHERE `CreatureID`=27737;
UPDATE `tmp_titan_plague_model` SET `CreatureID`=900122;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_plague_model`;

TRUNCATE TABLE `tmp_titan_plague_model`;
INSERT INTO `tmp_titan_plague_model`
SELECT * FROM `creature_template_model` WHERE `CreatureID`=68;
UPDATE `tmp_titan_plague_model` SET `CreatureID`=900123;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_plague_model`;
DROP TEMPORARY TABLE `tmp_titan_plague_model`;
