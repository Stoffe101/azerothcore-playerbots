-- Mysterious Cauldron for Blood-family Defense Protocol Beta/Gamma.
-- Reuse a stock WotLK cauldron model so an unmodified 3.3.5 client can render it.
-- GameObject::Use invokes the bound GameObjectScript before stock type behavior, so the custom
-- script owns the interaction and the cloned source object's original spell is never executed.

DELETE FROM `gameobject_template` WHERE `entry`=900120;

DROP TEMPORARY TABLE IF EXISTS `tmp_titan_cauldron`;
CREATE TEMPORARY TABLE `tmp_titan_cauldron` LIKE `gameobject_template`;

-- Arcane Protection Cauldron is the preferred stock cauldron visual. Fall back to the Frost
-- Protection Cauldron if a world-data revision omits the first template.
INSERT INTO `tmp_titan_cauldron`
SELECT * FROM `gameobject_template`
WHERE `entry` IN (186149,186155)
ORDER BY (`entry`=186149) DESC
LIMIT 1;

UPDATE `tmp_titan_cauldron`
SET `entry`=900120,
    `name`='Mysterious Cauldron',
    `IconName`='',
    `castBarCaption`='',
    `ScriptName`='go_titan_blood_cauldron';

INSERT INTO `gameobject_template` SELECT * FROM `tmp_titan_cauldron`;
DROP TEMPORARY TABLE `tmp_titan_cauldron`;
