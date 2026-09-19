-- Optional in-dungeon Titan Rune activation for the WotLK 3.3.5a backport.
-- The real Wrath Classic Mysterious Device/confirmation orb do not exist in the original 3.3.5
-- client DBCs, so these scripted gossip creatures deliberately reuse a client-native cauldron
-- display. The Dalaran coordinator/.titan preselection path remains available in parallel.

DELETE FROM `creature_template` WHERE `entry` IN (900113,900114);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_device_creature`;
CREATE TEMPORARY TABLE `tmp_titan_device_creature` LIKE `creature_template`;

-- Entry 11152 is a stock Scourge Cauldron and was already proven usable by the historical
-- Titan Rune prototype. It gives the selector a device-like native 3.3.5 visual with no MPQ patch.
INSERT INTO `tmp_titan_device_creature` SELECT * FROM `creature_template` WHERE `entry`=11152 LIMIT 1;
UPDATE `tmp_titan_device_creature`
SET `entry`=900113,
    `name`='Mysterious Device',
    `subname`='<Defense Protocol Interface>',
    `minlevel`=80,
    `maxlevel`=80,
    `faction`=35,
    `npcflag`=1,
    `AIName`='',
    `ScriptName`='npc_titan_mysterious_device';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_device_creature`;

TRUNCATE TABLE `tmp_titan_device_creature`;
INSERT INTO `tmp_titan_device_creature` SELECT * FROM `creature_template` WHERE `entry`=11152 LIMIT 1;
UPDATE `tmp_titan_device_creature`
SET `entry`=900114,
    `name`='Defense Protocol Orb',
    `subname`='<Party Confirmation Channel>',
    `minlevel`=80,
    `maxlevel`=80,
    `faction`=35,
    `npcflag`=1,
    `AIName`='',
    `ScriptName`='npc_titan_protocol_orb';
INSERT INTO `creature_template` SELECT * FROM `tmp_titan_device_creature`;
DROP TEMPORARY TABLE `tmp_titan_device_creature`;

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (900113,900114);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_device_model`;
CREATE TEMPORARY TABLE `tmp_titan_device_model` LIKE `creature_template_model`;
INSERT INTO `tmp_titan_device_model` SELECT * FROM `creature_template_model` WHERE `CreatureID`=11152;
UPDATE `tmp_titan_device_model` SET `CreatureID`=900113;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_device_model`;
TRUNCATE TABLE `tmp_titan_device_model`;
INSERT INTO `tmp_titan_device_model` SELECT * FROM `creature_template_model` WHERE `CreatureID`=11152;
UPDATE `tmp_titan_device_model` SET `CreatureID`=900114;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_titan_device_model`;
DROP TEMPORARY TABLE `tmp_titan_device_model`;
