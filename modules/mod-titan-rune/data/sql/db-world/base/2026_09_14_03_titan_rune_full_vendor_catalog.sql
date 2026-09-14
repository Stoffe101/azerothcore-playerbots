-- Complete Wrath Classic Defense Protocol Beta/Gamma exchange catalogs.
--
-- The 3.3.5 client cannot display the 3.4.x currency/NPC implementation, so this backport keeps the
-- existing scripted neutral vendors and exposes the complete item catalogs through them. For Gamma
-- the neutral quartermaster deliberately contains the UNION of Korralin Hoperender (Alliance) and
-- Kolara Dreamsmasher (Horde), ensuring every faction-specific Classic reward remains obtainable on
-- a private server without custom client DBCs.
--
-- Rows resolve stock 3.3.5 item_template entries by exact item name. Missing data rows are skipped
-- safely by INSERT ... SELECT, while all items present in the normal AzerothCore WotLK DB are added.

DELETE FROM `mod_titan_rune_vendor_items` WHERE `vendor` IN (1,2);

-- ============================================================================
-- Animated Constellation: Sidereal Essence (Defense Protocol Beta)
-- ============================================================================

-- 38 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,10 FROM item_template WHERE name='Aesir''s Edge' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,20 FROM item_template WHERE name='Icecore Staff' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,30 FROM item_template WHERE name='Tortured Earth' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,40 FROM item_template WHERE name='Hammer of Crushing Whispers' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,50 FROM item_template WHERE name='Magnetized Projectile Emitter' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,60 FROM item_template WHERE name='Fusion Blade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,38,70 FROM item_template WHERE name='Aesuga, Hand of the Ardent Champion' LIMIT 1;

-- 32 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,32,80 FROM item_template WHERE name='Breastplate of the Timeless' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,32,90 FROM item_template WHERE name='Zodiac Leggings' LIMIT 1;

-- 25 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,100 FROM item_template WHERE name='The Masticator' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,110 FROM item_template WHERE name='Perilous Bite' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,120 FROM item_template WHERE name='Shiver' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,130 FROM item_template WHERE name='The Boreal Guard' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,140 FROM item_template WHERE name='Ice Layered Barrier' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,150 FROM item_template WHERE name='Combatant''s Bootblade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,160 FROM item_template WHERE name='Serilas, Blood Blade of Invar One-Arm' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,170 FROM item_template WHERE name='Void Sabre' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,180 FROM item_template WHERE name='Caress of Insanity' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,190 FROM item_template WHERE name='Gilded Steel Legplates' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,200 FROM item_template WHERE name='Breastplate of the Stoneshaper' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,210 FROM item_template WHERE name='Fused Alloy Legplates' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,220 FROM item_template WHERE name='Mimiron''s Flight Goggles' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,25,230 FROM item_template WHERE name='Leggings of Profound Darkness' LIMIT 1;

-- 24 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,240 FROM item_template WHERE name='Shoulderplates of the Celestial Watch' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,250 FROM item_template WHERE name='Dark Matter' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,260 FROM item_template WHERE name='Starfall Girdle' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,270 FROM item_template WHERE name='Gloves of the Endless Dark' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,280 FROM item_template WHERE name='Observer''s Mantle' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,290 FROM item_template WHERE name='Pulsar Gloves' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,300 FROM item_template WHERE name='Starlight Treads' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,24,310 FROM item_template WHERE name='Meteorite Crystal' LIMIT 1;

-- 19 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,320 FROM item_template WHERE name='Handguards of Potent Cures' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,330 FROM item_template WHERE name='Mantle of Fiery Vengeance' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,340 FROM item_template WHERE name='Belt of the Crystal Tree' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,350 FROM item_template WHERE name='Gauntlets of the Thunder God' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,360 FROM item_template WHERE name='Sif''s Remembrance' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,370 FROM item_template WHERE name='Mjolnir Runestone' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,380 FROM item_template WHERE name='Gloves of Whispering Winds' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,390 FROM item_template WHERE name='Greaves of the Iron Army' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,400 FROM item_template WHERE name='Tempered Mercury Greaves' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,410 FROM item_template WHERE name='Strength of the Heavens' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,420 FROM item_template WHERE name='Drape of the Messenger' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,430 FROM item_template WHERE name='Nebula Band' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,440 FROM item_template WHERE name='Pendant of the Somber Witness' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,450 FROM item_template WHERE name='Band of Lights' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,460 FROM item_template WHERE name='Amice of Inconceivable Horror' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,470 FROM item_template WHERE name='Soul-Devouring Cinch' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,19,480 FROM item_template WHERE name='Vanquished Clutches of Yogg-Saron' LIMIT 1;

-- 15 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,490 FROM item_template WHERE name='Petrified Ivy Sprig' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,500 FROM item_template WHERE name='Twirling Blades' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,510 FROM item_template WHERE name='Shimmering Seal' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,520 FROM item_template WHERE name='Watchful Eye of Fate' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,530 FROM item_template WHERE name='Loop of the Agile' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,540 FROM item_template WHERE name='Fluxing Energy Coils' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,550 FROM item_template WHERE name='Seal of Ulduar' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,560 FROM item_template WHERE name='Bitter Cold Armguards' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,570 FROM item_template WHERE name='Pendant of the Shallow Grave' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,580 FROM item_template WHERE name='Seed of Budding Carnage' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,590 FROM item_template WHERE name='Fire Orchid Signet' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,600 FROM item_template WHERE name='Drape of the Faceless General' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,15,610 FROM item_template WHERE name='Signet of Soft Lament' LIMIT 1;

-- 3 Sidereal Essence
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 1,entry,3,620 FROM item_template WHERE name='Crusader Orb' LIMIT 1;

-- ============================================================================
-- Defiler's Scourgestone: union of Alliance and Horde Gamma catalogs
-- ============================================================================

-- 76 Scourgestones: faction weapon sets
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,10 FROM item_template WHERE name='Talonstrike' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,20 FROM item_template WHERE name='Justicebringer' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,30 FROM item_template WHERE name='Lupine Longstaff' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,40 FROM item_template WHERE name='Archon Glaive' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,50 FROM item_template WHERE name='Death''s Head Crossbow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,60 FROM item_template WHERE name='Dual-blade Butcher' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,70 FROM item_template WHERE name='Twin''s Pact' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,76,80 FROM item_template WHERE name='Hellion Glaive' LIMIT 1;

-- 60 Scourgestones: shared Ulduar hard-mode set plus faction weapon pair
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,90 FROM item_template WHERE name='Pendant of Fiery Havoc' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,100 FROM item_template WHERE name='Drape of Mortal Downfall' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,110 FROM item_template WHERE name='Sapphire Amulet of Renewal' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,120 FROM item_template WHERE name='Charm of Meticulous Timing' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,130 FROM item_template WHERE name='Frigid Strength of Hodir' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,140 FROM item_template WHERE name='Drape of Icy Intent' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,150 FROM item_template WHERE name='Fate''s Clutch' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,160 FROM item_template WHERE name='Bronze Pendant of the Vanir' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,170 FROM item_template WHERE name='Drape of the Sullen Goddess' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,180 FROM item_template WHERE name='Conductive Seal' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,190 FROM item_template WHERE name='Titanskin Cloak' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,200 FROM item_template WHERE name='Pendulum of Infinity' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,210 FROM item_template WHERE name='Flare of the Heavens' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,220 FROM item_template WHERE name='Seal of the Betrayed King' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,230 FROM item_template WHERE name='Show of Faith' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,240 FROM item_template WHERE name='Comet''s Trail' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,250 FROM item_template WHERE name='Blade of Tarasque' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,260 FROM item_template WHERE name='Misery''s End' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,270 FROM item_template WHERE name='Barb of Tarasque' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,60,280 FROM item_template WHERE name='Suffering''s End' LIMIT 1;

-- 50 Scourgestones: faction weapon/shield sets
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,290 FROM item_template WHERE name='Steel Bladebreaker' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,300 FROM item_template WHERE name='Crystal Plated Vanguard' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,310 FROM item_template WHERE name='Lionhead Slasher' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,320 FROM item_template WHERE name='Bastion of Purity' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,330 FROM item_template WHERE name='Twin Spike' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,340 FROM item_template WHERE name='Stormpike Cleaver' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,350 FROM item_template WHERE name='Stygian Bladebreaker' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,360 FROM item_template WHERE name='Forlorn Barrier' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,370 FROM item_template WHERE name='Blood Fury' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,380 FROM item_template WHERE name='Bastion of Resolve' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,390 FROM item_template WHERE name='Gouge of the Frigid Heart' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,50,400 FROM item_template WHERE name='Hellscream Slicer' LIMIT 1;

-- 38 Scourgestones: Alliance set
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,410 FROM item_template WHERE name='Cord of the Tenebrous Mist' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,420 FROM item_template WHERE name='Boots of the Courageous' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,430 FROM item_template WHERE name='Boots of the Unrelenting Storm' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,440 FROM item_template WHERE name='Belt of the Ice Burrower' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,450 FROM item_template WHERE name='Dawnbreaker Greaves' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,460 FROM item_template WHERE name='Bloodbath Belt' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,470 FROM item_template WHERE name='Solace of the Defeated' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,480 FROM item_template WHERE name='Treads of the Icewalker' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,490 FROM item_template WHERE name='Girdle of Bloodied Scars' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,500 FROM item_template WHERE name='Satrina''s Impeding Scarab' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,510 FROM item_template WHERE name='Cord of Biting Cold' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,520 FROM item_template WHERE name='Boots of Tremoring Earth' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,530 FROM item_template WHERE name='Boots of the Mourning Widow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,540 FROM item_template WHERE name='Sabatons of Ruthless Judgment' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,550 FROM item_template WHERE name='Belt of the Merciless Killer' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,560 FROM item_template WHERE name='Death''s Verdict' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,570 FROM item_template WHERE name='Cord of Pale Thorns' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,580 FROM item_template WHERE name='Greaves of the 7th Legion' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,590 FROM item_template WHERE name='Belt of Deathly Dominion' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,600 FROM item_template WHERE name='Reign of the Unliving' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,610 FROM item_template WHERE name='Footpads of the Icy Floe' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,620 FROM item_template WHERE name='Belt of the Forgotten Martyr' LIMIT 1;

-- 38 Scourgestones: Horde set
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,630 FROM item_template WHERE name='Belt of the Tenebrous Mist' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,640 FROM item_template WHERE name='Boots of the Harsh Winter' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,650 FROM item_template WHERE name='Sabatons of the Courageous' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,660 FROM item_template WHERE name='Binding of the Ice Burrower' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,670 FROM item_template WHERE name='Bloodbath Girdle' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,680 FROM item_template WHERE name='Dawnbreaker Sabatons' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,690 FROM item_template WHERE name='Solace of the Fallen' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,700 FROM item_template WHERE name='Belt of Bloodied Scars' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,710 FROM item_template WHERE name='Icewalker Treads' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,720 FROM item_template WHERE name='Belt of Biting Cold' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,730 FROM item_template WHERE name='Juggernaut''s Vitality' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,740 FROM item_template WHERE name='Sandals of the Mourning Widow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,750 FROM item_template WHERE name='Sabatons of Tremoring Earth' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,760 FROM item_template WHERE name='Greaves of Ruthless Judgment' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,770 FROM item_template WHERE name='Belt of the Pitiless Killer' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,780 FROM item_template WHERE name='Death''s Choice' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,790 FROM item_template WHERE name='Belt of Pale Thorns' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,800 FROM item_template WHERE name='Waistguard of Deathly Dominion' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,810 FROM item_template WHERE name='Greaves of the Saronite Citadel' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,820 FROM item_template WHERE name='Reign of the Dead' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,830 FROM item_template WHERE name='Boots of the Icy Floe' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,38,840 FROM item_template WHERE name='Girdle of the Forgotten Martyr' LIMIT 1;

-- 30 Scourgestones: Alliance set
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,850 FROM item_template WHERE name='Band of the Violent Temperment' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,860 FROM item_template WHERE name='Boneshatter Armplates' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,870 FROM item_template WHERE name='Drape of the Untamed Predator' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,880 FROM item_template WHERE name='Shawl of the Refreshing Winds' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,890 FROM item_template WHERE name='Pride of the Eredar' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,900 FROM item_template WHERE name='Charge of the Demon Lord' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,910 FROM item_template WHERE name='Symbol of Transgression' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,920 FROM item_template WHERE name='Band of Deplorable Violence' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,930 FROM item_template WHERE name='Bracers of the Autumn Willow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,940 FROM item_template WHERE name='Bracers of Cloudy Omen' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,950 FROM item_template WHERE name='Ring of Callous Aggression' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,960 FROM item_template WHERE name='Bracers of the Untold Massacre' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,970 FROM item_template WHERE name='Cloak of Displacement' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,980 FROM item_template WHERE name='Vambraces of the Broken Bond' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,990 FROM item_template WHERE name='The Executioner''s Malice' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1000 FROM item_template WHERE name='Bracers of the Shieldmaiden' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1010 FROM item_template WHERE name='The Arbiter''s Muse' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1020 FROM item_template WHERE name='Chalice of Searing Light' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1030 FROM item_template WHERE name='Wail of the Val''kyr' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1040 FROM item_template WHERE name='Bindings of Dark Essence' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1050 FROM item_template WHERE name='Signet of the Traitor King' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1060 FROM item_template WHERE name='Bracers of Dark Determination' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1070 FROM item_template WHERE name='Strength of the Nerub' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1080 FROM item_template WHERE name='Armbands of the Ashen Saint' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1090 FROM item_template WHERE name='Ring of the Darkmender' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1100 FROM item_template WHERE name='Maiden''s Favor' LIMIT 1;

-- 30 Scourgestones: Horde set
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1110 FROM item_template WHERE name='Ring of the Violent Temperament' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1120 FROM item_template WHERE name='Boneshatter Vambraces' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1130 FROM item_template WHERE name='Drape of the Refreshing Winds' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1140 FROM item_template WHERE name='Cloak of the Untamed Predator' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1150 FROM item_template WHERE name='Charge of the Eredar' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1160 FROM item_template WHERE name='Pride of the Demon Lord' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1170 FROM item_template WHERE name='Talisman of Heedless Sins' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1180 FROM item_template WHERE name='Bindings of the Autumn Willow' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1190 FROM item_template WHERE name='Circle of the Darkmender' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1200 FROM item_template WHERE name='Wristwraps of Cloudy Omen' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1210 FROM item_template WHERE name='Bracers of the Silent Massacre' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1220 FROM item_template WHERE name='Band of Callous Aggression' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1230 FROM item_template WHERE name='Shroud of Displacement' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1240 FROM item_template WHERE name='Bracers of the Broken Bond' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1250 FROM item_template WHERE name='The Executioner''s Vice' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1260 FROM item_template WHERE name='Armguards of the Shieldmaiden' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1270 FROM item_template WHERE name='Legionnaire''s Gorget' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1280 FROM item_template WHERE name='Dark Essence Bindings' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1290 FROM item_template WHERE name='Cry of the Val''kyr' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1300 FROM item_template WHERE name='Mystifying Charm' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1310 FROM item_template WHERE name='Armbands of Dark Determination' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1320 FROM item_template WHERE name='Band of the Traitor King' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1330 FROM item_template WHERE name='Might of the Nerub' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1340 FROM item_template WHERE name='Bindings of the Ashen Saint' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1350 FROM item_template WHERE name='Lurid Manifestation' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,30,1360 FROM item_template WHERE name='Maiden''s Adoration' LIMIT 1;

-- Shared exchanges represented as ordinary scripted-vendor purchases in the 3.3.5 backport.
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,20,1370 FROM item_template WHERE name='Trophy of the Crusade' LIMIT 1;
INSERT IGNORE INTO `mod_titan_rune_vendor_items` SELECT 2,entry,12,1380 FROM item_template WHERE name='Primordial Saronite' LIMIT 1;
-- 1 Scourgestone -> 1 Sidereal Essence remains a dedicated gossip action because Sidereal Essence
-- is the custom server-side item 900100 rather than a stock item_template row resolved by name.
