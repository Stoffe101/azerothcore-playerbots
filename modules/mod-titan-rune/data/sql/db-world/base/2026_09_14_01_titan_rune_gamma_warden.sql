-- Defense Protocol Gamma helper Warden.
-- Clone a stock 3.3.5-friendly humanoid template so no client DBC patch is needed.
DELETE FROM `creature_template` WHERE `entry`=900121;

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_gamma_warden`;
CREATE TEMPORARY TABLE `tmp_titan_gamma_warden` LIKE `creature_template`;
INSERT INTO `tmp_titan_gamma_warden`
SELECT * FROM `creature_template` WHERE `entry`=68 LIMIT 1;
UPDATE `tmp_titan_gamma_warden`
SET `entry`=900121,
    `name`='Titan Rune Warden',
    `subname`='<Defense Protocol Gamma>',
    `minlevel`=80,
    `maxlevel`=80,
    `faction`=35,
    `npcflag`=1,
    `ScriptName`='npc_titan_gamma_warden';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_gamma_warden`;
DROP TEMPORARY TABLE `tmp_titan_gamma_warden`;

DELETE FROM `creature_template_model` WHERE `CreatureID`=900121;
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_gamma_warden_model`;
CREATE TEMPORARY TABLE `tmp_titan_gamma_warden_model` LIKE `creature_template_model`;
INSERT INTO `tmp_titan_gamma_warden_model`
SELECT * FROM `creature_template_model` WHERE `CreatureID`=68;
UPDATE `tmp_titan_gamma_warden_model` SET `CreatureID`=900121;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_gamma_warden_model`;
DROP TEMPORARY TABLE `tmp_titan_gamma_warden_model`;
