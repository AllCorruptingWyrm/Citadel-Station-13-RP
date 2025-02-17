
//! Reference to any open turf that might be above us to speed up atom Entered() updates.
/turf/var/tmp/turf/above
/turf/var/tmp/turf/below
/// If we're a non-overwrite z-turf, this holds the appearance of the bottom-most Z-turf in the z-stack.
/turf/var/tmp/atom/movable/openspace/turf_proxy/mimic_proxy
/// Overlay used to multiply color of all OO overlays at once.
/turf/var/tmp/atom/movable/openspace/multiplier/shadower
/// If this is a delegate (non-overwrite) Z-turf with a z-turf above, this is the delegate copy that's copying us.
/turf/var/tmp/atom/movable/openspace/turf_mimic/mimic_above_copy
/// If we're at the bottom of the stack, a proxy used to fake a below space turf.
/turf/var/tmp/atom/movable/openspace/turf_proxy/mimic_underlay
/// How many times this turf is currently queued - multiple queue occurrences are allowed to ensure update consistency.
/turf/var/tmp/z_queued = 0
/// If this Z-turf leads to space, uninterrupted.
/turf/var/tmp/z_eventually_space = FALSE

//! debug
/turf/var/tmp/z_depth
/turf/var/tmp/z_generation = 0

/turf/update_above()
	if (TURF_IS_MIMICKING(above))
		above.update_mimic()

/turf/proc/update_mimic()
	if(mz_flags & MZ_MIMIC_BELOW)
		z_queued += 1
		// This adds duplicates for a reason. Do not change this unless you understand how ZM queues work.
		SSzmimic.queued_turfs += src

/// Enables Z-mimic for a turf that didn't already have it enabled.
/turf/proc/enable_zmimic(additional_flags = 0)
	if (mz_flags & MZ_MIMIC_BELOW)
		return FALSE

	mz_flags |= MZ_MIMIC_BELOW | additional_flags
	setup_zmimic(FALSE)
	return TRUE

/// Disables Z-mimic for a turf.
/turf/proc/disable_zmimic()
	if (!(mz_flags & MZ_MIMIC_BELOW))
		return FALSE

	mz_flags &= ~MZ_MIMIC_BELOW
	cleanup_zmimic()
	return TRUE

/// Sets up Z-mimic for this turf. You shouldn't call this directly 99% of the time.
/turf/proc/setup_zmimic(mapload)
	if (shadower)
		CRASH("Attempt to enable Z-mimic on already-enabled turf!")
	shadower = new(src)
	SSzmimic.openspace_turfs += 1
	var/turf/under = GetBelow(src)
	if (under)
		below = under
		below.above = src

	if (!(mz_flags & (MZ_MIMIC_OVERWRITE|MZ_NO_OCCLUDE)) && mouse_opacity)
		mouse_opacity = MOUSE_OPACITY_OPAQUE

	update_mimic(!mapload) // Only recursively update if the map isn't loading.

/// Cleans up Z-mimic objects for this turf. You shouldn't call this directly 99% of the time.
/turf/proc/cleanup_zmimic()
	SSzmimic.openspace_turfs -= 1
	// Don't remove ourselves from the queue, the subsystem will explode. We'll naturally fall out of the queue.
	z_queued = 0

	// can't use QDEL_NULL as we need to supply force to qdel
	if(shadower)
		qdel(shadower, TRUE)
		shadower = null
	QDEL_NULL(mimic_above_copy)
	QDEL_NULL(mimic_underlay)

	for (var/atom/movable/openspace/mimic/OO in src)
		OO.owning_turf_changed()

	if (above)
		above.update_mimic()

	if (below)
		below.above = null
		below = null

/turf/Entered(atom/movable/thing, atom/oldLoc)
	..()
	if (thing.bound_overlay || (thing.zmm_flags & ZMM_IGNORE) || thing.invisibility == INVISIBILITY_ABSTRACT || !TURF_IS_MIMICKING(above))
		return
	above.update_mimic()
