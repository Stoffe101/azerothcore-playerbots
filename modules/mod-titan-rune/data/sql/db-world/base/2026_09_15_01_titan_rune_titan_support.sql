-- Defense Protocol Beta/Gamma Titan Rune support for Halls of Stone / Halls of Lightning.
-- Wrath Classic's Immortal Crusher entry does not exist in the original 3.3.5a client data, so
-- clone the native Ulduar Crusher Tentacle visual and bind it to the backport AI.

DELETE FROM `creature_template` WHERE `entry`=900124;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_crusher_creature`;
CREATE TEMPORARY TABLE `tmp_titan_crusher_creature` LIKE `creature_template`;

INSERT INTO `tmp_titan_crusher_creature`
SELECT * FROM `creature_template` WHERE `entry`=33966 LIMIT 1;
UPDATE `tmp_titan_crusher_creature`
SET `entry`=900124,
    `difficulty_entry_1`=0,
    `name`='Immortal Crusher Tentacle',
    `subname`='<Defense Protocol Titan Rune>',
    `minlevel`=82,
    `maxlevel`=82,
    `rank`=1,
    `faction`=14,
    `npcflag`=0,
    `unit_flags`=0,
    `AIName`='',
    `ScriptName`='npc_titan_immortal_crusherAI',
    `HealthModifier`=3.0,
    `DamageModifier`=1.0;
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_crusher_creature`;
DROP TEMPORARY TABLE `tmp_titan_crusher_creature`;

DELETE FROM `creature_template_model` WHERE `CreatureID`=900124;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_crusher_model`;
CREATE TEMPORARY TABLE `tmp_titan_crusher_model` LIKE `creature_template_model`;
INSERT INTO `tmp_titan_crusher_model`
SELECT * FROM `creature_template_model` WHERE `CreatureID`=33966;
UPDATE `tmp_titan_crusher_model` SET `CreatureID`=900124;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_crusher_model`;
DROP TEMPORARY TABLE `tmp_titan_crusher_model`;
