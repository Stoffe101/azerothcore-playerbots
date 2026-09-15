-- Wrath Classic Gamma gives every player a faction signet that can resummon the Warden.
-- Original 3.3.5 has no Gamma signet item, so clone a native reusable use-item and let the
-- ItemScript suppress its stock spell. This keeps the item right-clickable without a client patch.
DELETE FROM `item_template` WHERE `entry` IN (900104,900105);
DROP TEMPORARY TABLE IF EXISTS `tmp_titan_signet`;
CREATE TEMPORARY TABLE `tmp_titan_signet` LIKE `item_template`;

-- Direbrew's Remote is a native, reusable right-click item. Its spell is never allowed to fire:
-- item_titan_gamma_signet returns true from OnUse after handling the Warden summon itself.
INSERT INTO `tmp_titan_signet` SELECT * FROM `item_template` WHERE `entry`=37863 LIMIT 1;
UPDATE `tmp_titan_signet`
SET `entry`=900104,
    `name`='Signet of the Silver Covenant',
    `description`='Use inside Defense Protocol Gamma to summon a Silver Covenant Warden. 2 minute cooldown.',
    `bonding`=1,
    `maxcount`=1,
    `stackable`=1,
    `ScriptName`='item_titan_gamma_signet';
INSERT INTO `item_template` SELECT * FROM `tmp_titan_signet`;

TRUNCATE TABLE `tmp_titan_signet`;
INSERT INTO `tmp_titan_signet` SELECT * FROM `item_template` WHERE `entry`=37863 LIMIT 1;
UPDATE `tmp_titan_signet`
SET `entry`=900105,
    `name`='Signet of the Sunreaver',
    `description`='Use inside Defense Protocol Gamma to summon a Sunreaver Warden. 2 minute cooldown.',
    `bonding`=1,
    `maxcount`=1,
    `stackable`=1,
    `ScriptName`='item_titan_gamma_signet';
INSERT INTO `item_template` SELECT * FROM `tmp_titan_signet`;
DROP TEMPORARY TABLE `tmp_titan_signet`;
