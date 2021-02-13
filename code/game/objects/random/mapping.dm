/*
//	Least descriptive filename?
//	This is where all of the things that aren't really loot should go.
//	Barricades, mines, etc.
*/

/obj/random/junk //Broken items, or stuff that could be picked up
	name = "random junk"
	desc = "This is some random junk."
	icon = 'icons/obj/trash.dmi'
	icon_state = "trashbag3"

/obj/random/junk/item_to_spawn()
	return get_random_junk_type()

/obj/random/trash //Mostly remains and cleanable decals. Stuff a janitor could clean up
	name = "random trash"
	desc = "This is some random trash."
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"

/obj/random/trash/item_to_spawn()
	return pick(/obj/effect/decal/remains/lizard,
				/obj/effect/decal/cleanable/blood/gibs/robot,
				/obj/effect/decal/cleanable/blood/oil,
				/obj/effect/decal/cleanable/blood/oil/streak,
				/obj/effect/decal/cleanable/spiderling_remains,
				/obj/effect/decal/remains/mouse,
				/obj/effect/decal/cleanable/vomit,
				/obj/effect/decal/cleanable/blood/splatter,
				/obj/effect/decal/cleanable/ash,
				/obj/effect/decal/cleanable/generic,
				/obj/effect/decal/cleanable/flour,
				/obj/effect/decal/cleanable/dirt,
				/obj/effect/decal/remains/robot)

/obj/random/obstruction //Large objects to block things off in maintenance
	name = "random obstruction"
	desc = "This is a random obstruction."
	icon = 'icons/obj/cult.dmi'
	icon_state = "cultgirder"

/obj/random/obstruction/item_to_spawn()
	return pick(/obj/structure/barricade,
				/obj/structure/girder,
				/obj/structure/girder/displaced,
				/obj/structure/girder/reinforced,
				/obj/structure/grille,
				/obj/structure/grille/broken,
				/obj/structure/foamedmetal,
				/obj/structure/inflatable,
				/obj/structure/inflatable/door)

/obj/random/landmine
	name = "Random Land Mine"
	desc = "This is a random land mine."
	icon = 'icons/obj/weapons.dmi'
	icon_state = "uglymine"
	spawn_nothing_percentage = 25

/obj/random/landmine/item_to_spawn()
	return pick(prob(30);/obj/effect/mine,
				prob(25);/obj/effect/mine/frag,
				prob(25);/obj/effect/mine/emp,
				prob(10);/obj/effect/mine/stun,
				prob(10);/obj/effect/mine/incendiary,)

/obj/random/humanoidremains
	name = "Random Humanoid Remains"
	desc = "This is a random pile of remains."
	spawn_nothing_percentage = 15
	icon = 'icons/effects/blood.dmi'
	icon_state = "remains"

/obj/random/humanoidremains/item_to_spawn()
	return pick(prob(30);/obj/effect/decal/remains/human,
				prob(25);/obj/effect/decal/remains/ribcage,
				prob(25);/obj/effect/decal/remains/tajaran,
				prob(10);/obj/effect/decal/remains/unathi,
				prob(10);/obj/effect/decal/remains/posi
				)

/obj/random_multi/single_item/captains_spare_id
	name = "Multi Point - Captain's Spare"
	id = "Captain's spare id"
	item_path = /obj/item/card/id/gold/captain/spare

/obj/random_multi/single_item/hand_tele
	name = "Multi Point - Hand Teleporter"
	id = "hand tele"
	item_path = /obj/item/hand_tele

/obj/random_multi/single_item/sfr_headset
	name = "Multi Point - headset"
	id = "SFR headset"
	item_path = /obj/random/sfr

// This is in here because it's spawned by the SFR Headset randomizer
/obj/random/sfr
	name = "random SFR headset"
	desc = "This is a headset spawn."
	icon = 'icons/misc/mark.dmi'
	icon_state = "rup"

/obj/random/sfr/item_to_spawn()
	return pick(prob(25);/obj/item/radio/headset/heads/captain/sfr,
				prob(25);/obj/item/radio/headset/headset_cargo/alt,
				prob(25);/obj/item/radio/headset/headset_com/alt,
				prob(25);/obj/item/radio/headset)

// Mining Goodies
/obj/random/multiple/minevault
	name = "random vault loot"
	desc = "Loot for mine vaults."
	icon = 'icons/obj/storage.dmi'
	icon_state = "crate"

/obj/random/multiple/minevault/item_to_spawn()
	return pick(
			prob(5);list(
				/obj/item/clothing/mask/smokable/pipe,
				/obj/item/reagent_containers/food/drinks/bottle/rum,
				/obj/item/reagent_containers/food/drinks/bottle/whiskey,
				/obj/item/reagent_containers/food/snacks/grown/ambrosiadeus,
				/obj/item/flame/lighter/zippo,
				/obj/structure/closet/crate/hydroponics
			),
			prob(5);list(
				/obj/item/pickaxe/drill,
				/obj/item/clothing/suit/space/void/mining,
				/obj/item/clothing/head/helmet/space/void/mining,
				/obj/structure/closet/crate/engineering
			),
			prob(5);list(
				/obj/item/pickaxe/drill,
				/obj/item/clothing/suit/space/void/mining/alt,
				/obj/item/clothing/head/helmet/space/void/mining/alt,
				/obj/structure/closet/crate/engineering
			),
			prob(5);list(
				/obj/item/reagent_containers/glass/beaker/bluespace,
				/obj/item/reagent_containers/glass/beaker/bluespace,
				/obj/item/reagent_containers/glass/beaker/bluespace,
				/obj/structure/closet/crate/science
			),
			prob(5);list(
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/diamond,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/item/ore/gold,
				/obj/structure/closet/crate/engineering
			),
			prob(5);list(
				/obj/item/pickaxe/drill,
				/obj/item/clothing/glasses/material,
				/obj/structure/ore_box,
				/obj/structure/closet/crate
			),
			prob(5);list(
				/obj/item/reagent_containers/glass/beaker/noreact,
				/obj/item/reagent_containers/glass/beaker/noreact,
				/obj/item/reagent_containers/glass/beaker/noreact,
				/obj/structure/closet/crate/science
			),
			prob(5);list(
				/obj/item/storage/secure/briefcase/money,
				/obj/structure/closet/crate/freezer/rations
			),
			prob(5);list(
				/obj/item/clothing/accessory/tie/horrible,
				/obj/item/clothing/accessory/tie/horrible,
				/obj/item/clothing/accessory/tie/horrible,
				/obj/item/clothing/accessory/tie/horrible,
				/obj/item/clothing/accessory/tie/horrible,
				/obj/item/clothing/accessory/tie/horrible,
				/obj/structure/closet/crate
			),
			prob(5);list(
				/obj/item/melee/baton,
				/obj/item/melee/baton,
				/obj/item/melee/baton,
				/obj/item/melee/baton,
				/obj/structure/closet/crate
			),
			prob(5);list(
				/obj/item/clothing/under/shorts/red,
				/obj/item/clothing/under/shorts/blue,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/item/melee/baton/cattleprod,
				/obj/item/melee/baton/cattleprod,
				/obj/item/cell/high,
				/obj/item/cell/high,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/item/latexballon,
				/obj/item/latexballon,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/item/toy/syndicateballoon,
				/obj/item/toy/syndicateballoon,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/item/rig/industrial/equipped,
				/obj/item/storage/bag/ore,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/clothing/head/kitty,
				/obj/item/clothing/head/kitty,
				/obj/item/clothing/head/kitty,
				/obj/item/clothing/head/kitty,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/random/coin,
				/obj/random/coin,
				/obj/random/coin,
				/obj/random/coin,
				/obj/random/coin,
				/obj/structure/closet/crate/plastic
			),
			prob(2);list(
				/obj/random/multiple/voidsuit,
				/obj/random/multiple/voidsuit,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/clothing/suit/space/syndicate/black/red,
				/obj/item/clothing/head/helmet/space/syndicate/black/red,
				/obj/item/clothing/suit/space/syndicate/black/red,
				/obj/item/clothing/head/helmet/space/syndicate/black/red,
				/obj/item/gun/projectile/automatic/mini_uzi,
				/obj/item/gun/projectile/automatic/mini_uzi,
				/obj/item/ammo_magazine/m45uzi,
				/obj/item/ammo_magazine/m45uzi,
				/obj/item/ammo_magazine/m45uzi/empty,
				/obj/item/ammo_magazine/m45uzi/empty,
				/obj/structure/closet/crate/plastic
			),
			prob(2);list(
				/obj/item/clothing/suit/ianshirt,
				/obj/item/clothing/suit/ianshirt,
				/obj/item/bedsheet/ian,
				/obj/structure/closet/crate/plastic
			),
			prob(2);list(
				/obj/item/clothing/suit/armor/vest,
				/obj/item/clothing/suit/armor/vest,
				/obj/item/gun/projectile/garand,
				/obj/item/gun/projectile/garand,
				/obj/item/ammo_magazine/m762garand,
				/obj/item/ammo_magazine/m762garand,
				/obj/structure/closet/crate/plastic
			),
			prob(2);list(
				/obj/mecha/working/ripley/mining
			),
			prob(2);list(
				/obj/mecha/working/hoverpod/combatpod
			),
			prob(2);list(
				/obj/item/pickaxe/silver,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/drill,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/jackhammer,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/diamond,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/diamonddrill,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/gold,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/pickaxe/plasmacutter,
				/obj/item/storage/bag/ore,
				/obj/item/clothing/glasses/material,
				/obj/structure/closet/crate/engineering
			),
			prob(2);list(
				/obj/item/material/sword/katana,
				/obj/item/material/sword/katana,
				/obj/structure/closet/crate
			),
			prob(2);list(
				/obj/item/material/sword,
				/obj/item/material/sword,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/clothing/mask/balaclava,
				/obj/item/material/star,
				/obj/item/material/star,
				/obj/item/material/star,
				/obj/item/material/star,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/weed_extract,
				/obj/item/xenos_claw,
				/obj/structure/closet/crate/science
			),
			prob(1);list(
				/obj/item/clothing/head/bearpelt,
				/obj/item/clothing/under/soviet,
				/obj/item/clothing/under/soviet,
				/obj/item/gun/projectile/shotgun/pump/rifle/ceremonial,
				/obj/item/gun/projectile/shotgun/pump/rifle/ceremonial,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/gun/projectile/revolver/detective,
				/obj/item/gun/projectile/contender,
				/obj/item/gun/projectile/p92x,
				/obj/item/gun/projectile/derringer,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/melee/cultblade,
				/obj/item/clothing/suit/cultrobes,
				/obj/item/clothing/head/culthood,
				/obj/item/soulstone,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/vampiric,
				/obj/item/vampiric,
				/obj/structure/closet/crate/science
			),
			prob(1);list(
				/obj/item/archaeological_find
			),
			prob(1);list(
				/obj/item/melee/energy/sword,
				/obj/item/melee/energy/sword,
				/obj/item/melee/energy/sword,
				/obj/item/shield/energy,
				/obj/item/shield/energy,
				/obj/structure/closet/crate/science
			),
			prob(1);list(
				/obj/item/storage/backpack/clown,
				/obj/item/clothing/under/rank/clown,
				/obj/item/clothing/shoes/clown_shoes,
				/obj/item/pda/clown,
				/obj/item/clothing/mask/gas/clown_hat,
				/obj/item/bikehorn,
				/obj/item/toy/waterflower,
				/obj/item/pen/crayon/rainbow,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/clothing/under/mime,
				/obj/item/clothing/shoes/black,
				/obj/item/pda/mime,
				/obj/item/clothing/gloves/white,
				/obj/item/clothing/mask/gas/mime,
				/obj/item/clothing/head/beret,
				/obj/item/clothing/suit/suspenders,
				/obj/item/pen/crayon/mime,
				/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/item/storage/belt/champion,
				/obj/item/clothing/mask/luchador,
				/obj/item/clothing/mask/luchador/rudos,
				/obj/item/clothing/mask/luchador/tecnicos,
				/obj/structure/closet/crate
			),
			prob(1);list(
				/obj/machinery/artifact,
				/obj/structure/anomaly_container
			),
			prob(1);list(
				/obj/random/curseditem,
				/obj/random/humanoidremains,
				/obj/structure/closet/crate
			)
		)

/*
 * Turf swappers.
 */

/obj/random/turf
	name = "random Sif turf"
	desc = "This is a random Sif turf."

	spawn_nothing_percentage = 20

	var/override_outdoors = FALSE	// Do we override our chosen turf's outdoors?
	var/turf_outdoors = TRUE	// Will our turf be outdoors?

/obj/random/turf/spawn_item()
	var/build_path = item_to_spawn()

	var/turf/T1 = get_turf(src)
	T1.ChangeTurf(build_path, 1, 1, FALSE)

	if(override_outdoors)
		T1.outdoors = turf_outdoors

/obj/random/turf/item_to_spawn()
	return pick(prob(25);/turf/simulated/floor/outdoors/grass/sif,
				prob(25);/turf/simulated/floor/outdoors/dirt,
				prob(25);/turf/simulated/floor/outdoors/grass/sif/forest,
				prob(25);/turf/simulated/floor/outdoors/rocks)

/obj/random/turf/lava
	name = "random Lava spawn"
	desc = "This is a random lava spawn."

	override_outdoors = TRUE
	turf_outdoors = FALSE

/obj/random/turf/lava/item_to_spawn()
	return pick(prob(5);/turf/simulated/floor/lava,
				prob(3);/turf/simulated/floor/outdoors/rocks/caves,
				prob(1);/turf/simulated/mineral)

/obj/random/trash_pile
	name = "Random Trash Pile"
	desc = "Hot Garbage."
	icon = 'icons/obj/trash_piles.dmi'
	icon_state = "randompile"
	spawn_nothing_percentage = 0

/obj/random/trash_pile/item_to_spawn()
	return	/obj/structure/trash_pile