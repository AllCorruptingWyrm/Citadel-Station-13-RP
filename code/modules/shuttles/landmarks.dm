// Making this separate from /obj/landmark until that mess can be dealt with
/obj/effect/shuttle_landmark
	name = "Nav Point"
	icon = 'icons/effects/effects.dmi'
	icon_state = "energynet"
	anchored = 1
	unacidable = 1
	atom_flags = ATOM_ABSTRACT
	invisibility = 101
	var/shuttle_landmark_flags = SLANDMARK_FLAG_AUTOSET	// We generally want to use current area/turf as base.

	// ID of the landmark
	var/landmark_tag
	// ID of the controller on the dock side (intialize to id_tag, becomes reference)
	var/datum/computer/file/embedded_program/docking/docking_controller
	// Map of shuttle names to ID of controller used for this landmark for shuttles with multiple ones.
	var/list/special_dock_targets

	// When the shuttle leaves this landmark, it will leave behind the base area,
	// 	also used to determine if the shuttle can arrive here without obstruction
	var/area/base_area
	// Will also leave this type of turf behind if set.
	var/turf/base_turf
	// Name of the shuttle, null for generic waypoint
	var/shuttle_restricted

/obj/effect/shuttle_landmark/Initialize(mapload)
	. = ..()
	if(docking_controller)
		. = INITIALIZE_HINT_LATELOAD

	if(shuttle_landmark_flags & SLANDMARK_FLAG_AUTOSET)
		if(ispath(base_area))
			var/area/A = locate(base_area)
			if(!istype(A))
				CRASH("Shuttle landmark \"[landmark_tag]\" couldn't locate area [base_area].")
			base_area = A
		else
			base_area = get_area(src)
		var/turf/T = get_turf(src)
		if(T && !base_turf)
			base_turf = T.type
	else
		base_area = locate(base_area || world.area)

	name = (name + " ([x],[y])")
	SSshuttle.register_landmark(landmark_tag, src)

/obj/effect/shuttle_landmark/LateInitialize()
	if(!docking_controller)
		return
	var/docking_tag = docking_controller
	docking_controller = SSshuttle.docking_registry[docking_tag]
	if(!istype(docking_controller))
		log_error("Could not find docking controller for shuttle waypoint '[name]', docking tag was '[docking_tag]'.")
	if(GLOB.using_map.use_overmap)
		var/obj/effect/overmap/visitable/location = get_overmap_sector(z)
		if(location && location.docking_codes)

			docking_controller.docking_codes = location.docking_codes

/obj/effect/shuttle_landmark/forceMove()
	var/obj/effect/overmap/visitable/map_origin = get_overmap_sector(z)
	. = ..()
	var/obj/effect/overmap/visitable/map_destination = get_overmap_sector(z)
	if(map_origin != map_destination)
		if(map_origin)
			map_origin.remove_landmark(src, shuttle_restricted)
		if(map_destination)
			map_destination.add_landmark(src, shuttle_restricted)

// Called when the landmark is added to an overmap sector.
/obj/effect/shuttle_landmark/proc/sector_set(var/obj/effect/overmap/visitable/O, shuttle_name)
	shuttle_restricted = shuttle_name

/obj/effect/shuttle_landmark/proc/is_valid(var/datum/shuttle/shuttle)
	if(shuttle.current_location == src)
		return FALSE
	for(var/area/A in shuttle.shuttle_area)
		var/list/translation = get_turf_translation(get_turf(shuttle.current_location), get_turf(src), A.contents)
		if(check_collision(base_area, list_values(translation)))
			return FALSE
	var/conn = GetConnectedZlevels(z)
	for(var/w in (z - shuttle.multiz) to z)
		if(!(w in conn))
			return FALSE
	return TRUE

// This creates a graphical warning to where the shuttle is about to land in approximately five seconds.
/obj/effect/shuttle_landmark/proc/create_warning_effect(var/datum/shuttle/shuttle)
	if(shuttle.current_location == src)
		return	// TOO LATE!
	for(var/area/A in shuttle.shuttle_area)
		var/list/translation = get_turf_translation(get_turf(shuttle.current_location), get_turf(src), A.contents)
		for(var/T in list_values(translation))
			new /obj/effect/temporary_effect/shuttle_landing(T)	// It'll delete itself when needed.
	return

// Should return a readable description of why not if it can't depart.
/obj/effect/shuttle_landmark/proc/cannot_depart(datum/shuttle/shuttle)
	return FALSE

/obj/effect/shuttle_landmark/proc/shuttle_departed(datum/shuttle/shuttle)
	return

/obj/effect/shuttle_landmark/proc/shuttle_arrived(datum/shuttle/shuttle)
	return

/proc/check_collision(area/target_area, list/target_turfs)
	for(var/target_turf in target_turfs)
		var/turf/target = target_turf
		if(!target)
			return TRUE	// Collides with edge of map
		if(target.loc != target_area)
			return TRUE	// Collides with another area
		if(target.density)
			return TRUE	// Dense turf
	return FALSE

//
// Self-naming/numbering ones.
//
/obj/effect/shuttle_landmark/automatic
	name = "Navpoint"
	landmark_tag = "navpoint"
	shuttle_landmark_flags = SLANDMARK_FLAG_AUTOSET
	var/original_name = null // Save our mapped-in name so we can rebuild our name when moving sectors.

/obj/effect/shuttle_landmark/automatic/Initialize(mapload)
	original_name = name
	landmark_tag += "-[x]-[y]-[z]-[random_id("landmarks",1,9999)]"
	return ..()

/obj/effect/shuttle_landmark/automatic/sector_set(var/obj/effect/overmap/visitable/O)
	..()
	name = ("[O.name] - [original_name] ([x],[y])")

// Subtype that calls explosion on init to clear space for shuttles
/obj/effect/shuttle_landmark/automatic/clearing
	var/radius = 10

/obj/effect/shuttle_landmark/automatic/clearing/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/shuttle_landmark/automatic/clearing/LateInitialize()
	..()
	for(var/turf/T in range(radius, src))
		if(T.density)
			T.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

// Subtype that also queues a shuttle datum (for shuttles starting on maps loaded at runtime)
/obj/effect/shuttle_landmark/shuttle_initializer
	var/datum/shuttle/shuttle_type

/obj/effect/shuttle_landmark/shuttle_initializer/Initialize(mapload)
	. = ..()
	LAZYADD(SSshuttle.shuttles_to_initialize, shuttle_type)	// Queue up for init.

//
// Bluespace flare landmark beacon
//
/obj/item/spaceflare
	name = "bluespace flare"
	desc = "Burst transmitter used to broadcast all needed information for shuttle navigation systems. Has a flare attached for marking the spot where you probably shouldn't be standing."
	icon_state = "bluflare"
	light_color = "#3728ff"
	var/active

/obj/item/spaceflare/attack_self(mob/user)
	. = ..()
	if(.)
		return
	if(!active)
		visible_message("<span class='notice'>[user] pulls the cord, activating the [src].</span>")
		activate()

/obj/item/spaceflare/proc/activate()
	if(active)
		return
	var/turf/T = get_turf(src)
	var/mob/M = loc
	if(istype(M) && !M.drop_item_to_ground(src))
		return

	active = 1
	anchored = 1

	var/obj/effect/shuttle_landmark/automatic/mark = new(T)
	mark.name = ("Beacon signal ([T.x],[T.y])")
	T.hotspot_expose(1500, 5)
	update_icon()

/obj/item/spaceflare/update_icon()
	. = ..()
	if(active)
		icon_state = "bluflare_on"
		set_light(0.3, 0.1, 6, 2, "85d1ff")
