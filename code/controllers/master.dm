/**
 * StonedMC
 *
 * Designed to properly split up a given tick among subsystems
 * Note: if you read parts of this code and think "why is it doing it that way"
 * Odds are, there is a reason
 *
 **/

/**
 * This is the ABSOLUTE ONLY THING that should init globally like this.
 */
GLOBAL_REAL(Master, /datum/controller/master) = new

/**
 * THIS IS THE INIT ORDER
 * Master -> SSPreInit -> GLOB -> world -> config -> SSInit -> Failsafe
 * GOT IT MEMORIZED?
 */

/datum/controller/master
	name = "Master"

	/// Are we processing (higher values increase the processing delay by n ticks)
	var/processing = TRUE

	/// How many times have we ran?
	var/iteration = 0

	/// Are we initialized?
	var/initialized = FALSE

	/// Are we loading in a new map?
	var/map_loading = FALSE

	/// world.time of last fire, for tracking lag outside of the mc.
	var/last_run

	/// List of subsystems to process().
	var/list/subsystems

	//# Vars for keeping track of tick drift.
	var/init_timeofday
	var/init_time
	var/tickdrift = 0

	/// How long is the MC sleeping between runs, read only (set by Loop() based off of anti-tick-contention heuristics).
	var/sleep_delta = 1

	/// Makes the mc main loop runtime.
	var/make_runtime = FALSE

	var/initializations_finished_with_no_players_logged_in // I wonder what this could be?

	/// The type of the last subsystem to be process()'d.
	var/last_type_processed

	/// Start of queue linked list.
	var/datum/controller/subsystem/queue_head

	/// End of queue linked list (used for appending to the list).
	var/datum/controller/subsystem/queue_tail

	/// Running total so that we don't have to loop thru the queue each run to split up the tick.
	var/queue_priority_count = 0

	/// Total background subsystems in the queue.
	var/queue_priority_count_bg = 0

	/// For scheduling different subsystems for different stages of the round.
	var/current_runlevel

	var/sleep_offline_after_initializations = TRUE

	var/static/restart_clear = 0
	var/static/restart_timeout = 0
	var/static/restart_count = 0

	var/static/random_seed

	/**
	 * current tick limit, assigned before running a subsystem.
	 * used by CHECK_TICK as well so that the procs subsystems call can obey that SS's tick limits.
	 */
	var/static/current_ticklimit = TICK_LIMIT_RUNNING


/datum/controller/master/New()
	//# 1. load configs
	if(!config_legacy)
		load_configuration()
	if(!config)
		config = new

	//# 2. set up random seed
	if(!random_seed)
		random_seed = (TEST_RUN_PARAMETER in world.params) ? 29051994 : rand(1, 1e9)
		rand_seed(random_seed)

	//# 3. create subsystems
	// Highlander-style: there can only be one! Kill off the old and replace it with the new.
	var/list/_subsystems = list()
	subsystems = _subsystems
	if (Master != src)
		if (istype(Master))
			Recover()
			qdel(Master)
		else
			var/list/subsytem_types = subtypesof(/datum/controller/subsystem)
			tim_sort(subsytem_types, /proc/cmp_subsystem_init)
			for(var/I in subsytem_types)
				var/datum/controller/subsystem/S = new I
				_subsystems += S
		Master = src

	/**
	 * # 4. call PreInit() on all subsystems
	 * we iterate on _subsystems because if we Recover(), we don't make any subsystems into _subsystems,
	 * as we instead have the old subsystems added to our normal subsystems list.
	 */
	for(var/datum/controller/subsystem/S in _subsystems)
		S.PreInit(FALSE)

	//# 5. set up globals
	if(!GLOB)
		new /datum/controller/global_vars

	/**
	 * # 6. call Preload() on all subsystems
	 * we iterate on _subsystems because if we Recover(), we don't make any subsystems into _subsystems,
	 * as we instead have the old subsystems added to our normal subsystems list.
	 */
	for(var/datum/controller/subsystem/S in _subsystems)
		S.Preload(FALSE)


/datum/controller/master/Destroy()
	..()
	// Tell qdel() to Del() this object.
	return QDEL_HINT_HARDDEL_NOW


/datum/controller/master/Shutdown()
	processing = FALSE
	tim_sort(subsystems, /proc/cmp_subsystem_init)
	reverseRange(subsystems)
	for(var/datum/controller/subsystem/ss in subsystems)
		log_world("Shutting down [ss.name] subsystem...")
		ss.Shutdown()

	log_world("Shutdown complete")


/**
 * Returns:
 * -  1 If we created a new mc.
 * -  0 If we couldn't due to a recent restart.
 * - -1 If we encountered a runtime trying to recreate it.
 */
/proc/Recreate_MC()
	. = -1 // So if we runtime, things know we failed.
	if (world.time < Master.restart_timeout)
		return 0
	if (world.time < Master.restart_clear)
		Master.restart_count *= 0.5

	var/delay = 50 * ++Master.restart_count
	Master.restart_timeout = world.time + delay
	Master.restart_clear = world.time + (delay * 2)
	Master.processing = FALSE // Stop ticking this one.
	try
		new/datum/controller/master()
	catch
		return -1

	return 1


/datum/controller/master/Recover()
	var/msg = "## DEBUG: [time2text(world.timeofday)] MC restarted. Reports:\n"
	for (var/varname in Master.vars)
		switch (varname)
			if("name", "tag", "bestF", "type", "parent_type", "vars", "statclick") // Built-in junk.
				continue

			else
				var/varval = Master.vars[varname]
				if (istype(varval, /datum)) // Check if it has a type var.
					var/datum/D = varval
					msg += "\t [varname] = [D]([D.type])\n"

				else
					msg += "\t [varname] = [varval]\n"

	log_world(msg)

	var/datum/controller/subsystem/BadBoy = Master.last_type_processed
	var/FireHim = FALSE
	if(istype(BadBoy))
		msg = null
		LAZYINITLIST(BadBoy.failure_strikes)
		switch(++BadBoy.failure_strikes[BadBoy.type])
			if(2)
				msg = "The [BadBoy.name] subsystem was the last to fire for 2 controller restarts. It will be recovered now and disabled if it happens again."
				FireHim = TRUE

			if(3)
				msg = "The [BadBoy.name] subsystem seems to be destabilizing the MC and will be offlined."
				BadBoy.subsystem_flags |= SS_NO_FIRE

		if(msg)
			to_chat(GLOB.admins, SPAN_BOLDANNOUNCE("[msg]"))
			log_world(msg)

	if (istype(Master.subsystems))
		if(FireHim)
			Master.subsystems += new BadBoy.type // NEW_SS_GLOBAL will remove the old one.

		subsystems = Master.subsystems
		current_runlevel = Master.current_runlevel
		initialized = TRUE
		StartProcessing(10)

	else
		to_chat(world, SPAN_BOLDANNOUNCE("The Master Controller is having some issues, we will need to re-initialize EVERYTHING"))
		Initialize(20, TRUE)


/**
 * Please don't stuff random bullshit here,
 * Make a subsystem, give it the SS_NO_FIRE flag, and do your work in it's Initialize()
 */
/datum/controller/master/Initialize(delay, init_sss, tgs_prime)
	set waitfor = FALSE

	if(delay)
		sleep(delay)

	if(tgs_prime)
		world.TgsInitializationComplete()

	if(init_sss)
		init_subtypes(/datum/controller/subsystem, subsystems)

	to_chat(world, SPAN_BOLDANNOUNCE("Initializing subsystems..."))

	// Sort subsystems by init_order, so they initialize in the correct order.
	tim_sort(subsystems, /proc/cmp_subsystem_init)

	var/start_timeofday = REALTIMEOFDAY
	// Initialize subsystems.
	current_ticklimit = config_legacy.tick_limit_mc_init
	for (var/datum/controller/subsystem/SS in subsystems)
		if (SS.subsystem_flags & SS_NO_INIT)
			continue

		SS.Initialize(REALTIMEOFDAY)
		CHECK_TICK

	current_ticklimit = TICK_LIMIT_RUNNING
	var/time = (REALTIMEOFDAY - start_timeofday) / 10

	var/msg = "Initializations complete within [time] second[time == 1 ? "" : "s"]!"
	to_chat(world, SPAN_BOLDANNOUNCE("[msg]"))
	log_world(msg)

	if (!current_runlevel)
		SetRunLevel(RUNLEVEL_LOBBY)

	// Sort subsystems by display setting for easy access.
	tim_sort(subsystems, /proc/cmp_subsystem_display)

	if(world.system_type == MS_WINDOWS && CONFIG_GET(flag/toast_notification_on_init) && !length(GLOB.clients))
		world.shelleo("start /min powershell -ExecutionPolicy Bypass -File tools/initToast/initToast.ps1 -name \"[world.name]\" -icon %CD%\\icons\\CS13_16.png -port [world.port]")

	// Set world options.

	world.fps = config_legacy.fps

	var/initialized_tod = REALTIMEOFDAY
	if(sleep_offline_after_initializations)
		world.sleep_offline = TRUE

	sleep(1)

	if(sleep_offline_after_initializations) // && CONFIG_GET(flag/resume_after_initializations))
		world.sleep_offline = FALSE

	initializations_finished_with_no_players_logged_in = initialized_tod < REALTIMEOFDAY - 10

	initialized = TRUE

	// Loop.
	Master.StartProcessing(0)


/datum/controller/master/proc/SetRunLevel(new_runlevel)
	var/old_runlevel = current_runlevel
	if(isnull(old_runlevel))
		old_runlevel = "NULL"

	testing("MC: Runlevel changed from [old_runlevel] to [new_runlevel]")
	current_runlevel = log(2, new_runlevel) + 1
	if(current_runlevel < 1)
		CRASH("Attempted to set invalid runlevel: [new_runlevel]")


/**
 * Starts the mc, and sticks around to restart it if the loop ever ends.
 */
/datum/controller/master/proc/StartProcessing(delay)
	set waitfor = FALSE

	if(delay)
		sleep(delay)

	testing("Master starting processing")
	var/rtn = Loop()
	if (rtn > 0 || processing < 0)
		return // This was suppose to happen.

	// Loop ended, restart the mc.
	log_game("MC crashed or runtimed, restarting")
	message_admins("MC crashed or runtimed, restarting")
	var/rtn2 = Recreate_MC()
	if (rtn2 <= 0)
		log_game("Failed to recreate MC (Error code: [rtn2]), it's up to the failsafe now")
		message_admins("Failed to recreate MC (Error code: [rtn2]), it's up to the failsafe now")
		Failsafe.defcon = 2


/**
 * Main loop!
 * This is where the magic happens.
 */
/datum/controller/master/proc/Loop()
	. = -1

	// Prep the loop (most of this is because we want MC restarts to reset as much state as we can, and because local vars rock

	// All this shit is here so that flag edits can be refreshed by restarting the MC. (and for speed)
	var/list/SStickersubsystems = list()
	var/list/runlevel_sorted_subsystems = list(list()) // Ensure we always have at least one runlevel.
	var/timer = world.time
	for (var/thing in subsystems)
		var/datum/controller/subsystem/SS = thing
		if (SS.subsystem_flags & SS_NO_FIRE)
			continue

		SS.queued_time = 0
		SS.queue_next = null
		SS.queue_prev = null
		SS.state = SS_IDLE
		if (SS.subsystem_flags & SS_TICKER)
			SStickersubsystems += SS
			// Timer subsystems aren't allowed to bunch up, so we offset them a bit.
			timer += world.tick_lag * rand(0, 1)
			SS.next_fire = timer
			continue

		var/ss_runlevels = SS.runlevels
		var/added_to_any = FALSE
		for(var/I in 1 to GLOB.bitflags.len)
			if(ss_runlevels & GLOB.bitflags[I])
				while(runlevel_sorted_subsystems.len < I)
					runlevel_sorted_subsystems += list(list())

				runlevel_sorted_subsystems[I] += SS
				added_to_any = TRUE

		if(!added_to_any)
			WARNING("[SS.name] subsystem is not SS_NO_FIRE but also does not have any runlevels set!")

	queue_head = null
	queue_tail = null

	/**
	 * These sort by lower priorities first to reduce the number of loops needed to add subsequent SS's to the queue.
	 * (higher subsystems will be sooner in the queue, adding them later in the loop means we don't have to loop thru them next queue add)
	 */
	tim_sort(SStickersubsystems, /proc/cmp_subsystem_priority)
	for(var/I in runlevel_sorted_subsystems)
		tim_sort(I, /proc/cmp_subsystem_priority)
		I += SStickersubsystems

	var/cached_runlevel = current_runlevel
	var/list/current_runlevel_subsystems = runlevel_sorted_subsystems[cached_runlevel]

	init_timeofday = REALTIMEOFDAY
	init_time = world.time

	iteration = 1
	var/error_level = 0
	var/sleep_delta = 1
	var/list/subsystems_to_check

	//# The actual loop.
	while (1)
		tickdrift = max(0, MC_AVERAGE_FAST(tickdrift, (((REALTIMEOFDAY - init_timeofday) - (world.time - init_time)) / world.tick_lag)))
		var/starting_tick_usage = TICK_USAGE
		if (processing <= 0)
			current_ticklimit = TICK_LIMIT_RUNNING
			sleep(10)
			continue

		/**
		 * Anti-tick-contention heuristics:
		 * If there are mutiple sleeping procs running before us hogging the cpu, we have to run later.
		 * (because sleeps are processed in the order received, longer sleeps are more likely to run first)
		 */
		if (starting_tick_usage > TICK_LIMIT_MC) // If there isn't enough time to bother doing anything this tick, sleep a bit.
			sleep_delta *= 2
			current_ticklimit = TICK_LIMIT_RUNNING * 0.5
			sleep(world.tick_lag * (processing * sleep_delta))
			continue

		/**
		 * Byond resumed us late.
		 * Assume it might have to do the same next tick.
		 */
		if (last_run + CEILING(world.tick_lag * (processing * sleep_delta), world.tick_lag) < world.time)
			sleep_delta += 1

		sleep_delta = MC_AVERAGE_FAST(sleep_delta, 1) // Decay sleep_delta.

		if (starting_tick_usage > (TICK_LIMIT_MC*0.75)) // We ran 3/4 of the way into the tick.
			sleep_delta += 1

		//# Debug.
		if (make_runtime)
			var/datum/controller/subsystem/SS
			SS.can_fire = 0

		if (!Failsafe || (Failsafe.processing_interval > 0 && (Failsafe.lasttick+(Failsafe.processing_interval*5)) < world.time))
			new/datum/controller/failsafe() // (re)Start the failsafe.

		//# Now do the actual stuff.
		if (!queue_head || !(iteration % 3))
			var/checking_runlevel = current_runlevel
			if(cached_runlevel != checking_runlevel)
				// Resechedule subsystems.
				var/list/old_subsystems = current_runlevel_subsystems
				cached_runlevel = checking_runlevel
				current_runlevel_subsystems = runlevel_sorted_subsystems[cached_runlevel]

				// Now we'll go through all the subsystems we want to offset and give them a next_fire.
				for(var/datum/controller/subsystem/SS as anything in current_runlevel_subsystems)
					// We only want to offset it if it's new and also behind.
					if(SS.next_fire > world.time || (SS in old_subsystems))
						continue

					SS.next_fire = world.time + world.tick_lag * rand(0, DS2TICKS(min(SS.wait, 2 SECONDS)))

			subsystems_to_check = current_runlevel_subsystems

		else
			subsystems_to_check = SStickersubsystems

		if (CheckQueue(subsystems_to_check) <= 0)
			if (!SoftReset(SStickersubsystems, runlevel_sorted_subsystems))
				log_world("MC: SoftReset() failed, crashing")
				return

			if (!error_level)
				iteration++

			error_level++
			current_ticklimit = TICK_LIMIT_RUNNING
			sleep(10)
			continue

		if (queue_head)
			if (RunQueue() <= 0)
				if (!SoftReset(SStickersubsystems, runlevel_sorted_subsystems))
					log_world("MC: SoftReset() failed, crashing")
					return

				if (!error_level)
					iteration++

				error_level++
				current_ticklimit = TICK_LIMIT_RUNNING
				sleep(10)
				continue

		error_level--
		if (!queue_head) // Reset the counts if the queue is empty, in the off chance they get out of sync.
			queue_priority_count = 0
			queue_priority_count_bg = 0

		iteration++
		last_run = world.time
		src.sleep_delta = MC_AVERAGE_FAST(src.sleep_delta, sleep_delta)
		current_ticklimit = TICK_LIMIT_RUNNING
		if (processing * sleep_delta <= world.tick_lag)
			current_ticklimit -= (TICK_LIMIT_RUNNING * 0.25) // Reserve the tail 1/4 of the next tick for the mc if we plan on running next tick.

		sleep(world.tick_lag * (processing * sleep_delta))


/**
 * This is what decides if something should run.
 *
 * Arguments:
 * * subsystemstocheck - List of systems to check.
 */
/datum/controller/master/proc/CheckQueue(list/subsystemstocheck)
	. = FALSE // So the mc knows if we runtimed.

	// We create our variables outside of the loops to save on overhead.
	var/datum/controller/subsystem/SS
	var/SS_flags

	for (var/thing in subsystemstocheck)
		if (!thing)
			subsystemstocheck -= thing

		SS = thing
		if (SS.state != SS_IDLE)
			continue

		if (SS.can_fire <= 0)
			continue

		if (SS.next_fire > world.time)
			continue

		SS_flags = SS.subsystem_flags
		if (SS_flags & SS_NO_FIRE)
			subsystemstocheck -= SS
			continue

		if ((SS_flags & (SS_TICKER|SS_KEEP_TIMING)) == SS_KEEP_TIMING && SS.last_fire + (SS.wait * 0.75) > world.time)
			continue

		SS.enqueue()

	. = TRUE


/// Run thru the queue of subsystems to run, running them while balancing out their allocated tick precentage.
/datum/controller/master/proc/RunQueue()
	. = FALSE
	var/datum/controller/subsystem/queue_node
	var/queue_node_flags
	var/queue_node_priority
	var/queue_node_paused

	var/current_tick_budget
	var/tick_precentage
	var/tick_remaining
	var/ran = TRUE // This is right.
	var/ran_non_SSticker = FALSE
	var/bg_calc // Have we swtiched current_tick_budget to background mode yet?
	var/tick_usage

	/**
	 * Keep running while we have stuff to run and we haven't gone over a tick
	 * this is so subsystems paused eariler can use tick time that later subsystems never used
	 */
	while (ran && queue_head && TICK_USAGE < TICK_LIMIT_MC)
		ran = FALSE
		bg_calc = FALSE
		current_tick_budget = queue_priority_count
		queue_node = queue_head
		while (queue_node)
			if (ran && TICK_USAGE > TICK_LIMIT_RUNNING)
				break

			queue_node_flags = queue_node.subsystem_flags
			queue_node_priority = queue_node.queued_priority

			/**
			 * Super special case, subsystems where we can't make them pause mid way through.
			 * If we can't run them this tick (without going over a tick) we bump up their priority and attempt to run them next tick.
			 * (unless we haven't even ran anything this tick, since its unlikely they will ever be able run in those cases, so we just let them run)
			 */
			if (queue_node_flags & SS_NO_TICK_CHECK)
				if (queue_node.tick_usage > TICK_LIMIT_RUNNING - TICK_USAGE && ran_non_SSticker)
					queue_node.queued_priority += queue_priority_count * 0.1
					queue_priority_count -= queue_node_priority
					queue_priority_count += queue_node.queued_priority
					current_tick_budget -= queue_node_priority
					queue_node = queue_node.queue_next
					continue

			if ((queue_node_flags & SS_BACKGROUND) && !bg_calc)
				current_tick_budget = queue_priority_count_bg
				bg_calc = TRUE

			tick_remaining = TICK_LIMIT_RUNNING - TICK_USAGE

			if (current_tick_budget > 0 && queue_node_priority > 0)
				tick_precentage = tick_remaining / (current_tick_budget / queue_node_priority)

			else
				tick_precentage = tick_remaining

			// Reduce tick allocation for subsystems that overran on their last tick.
			tick_precentage = max(tick_precentage*0.5, tick_precentage-queue_node.tick_overrun)

			current_ticklimit = round(TICK_USAGE + tick_precentage)

			if (!(queue_node_flags & SS_TICKER))
				ran_non_SSticker = TRUE

			ran = TRUE

			queue_node_paused = (queue_node.state == SS_PAUSED || queue_node.state == SS_PAUSING)
			last_type_processed = queue_node

			queue_node.state = SS_RUNNING

			tick_usage = TICK_USAGE
			var/state = queue_node.ignite(queue_node_paused)
			tick_usage = TICK_USAGE - tick_usage

			if (state == SS_RUNNING)
				state = SS_IDLE

			current_tick_budget -= queue_node_priority


			if (tick_usage < 0)
				tick_usage = 0

			queue_node.tick_overrun = max(0, MC_AVG_FAST_UP_SLOW_DOWN(queue_node.tick_overrun, tick_usage-tick_precentage))
			queue_node.state = state

			if (state == SS_PAUSED)
				queue_node.paused_ticks++
				queue_node.paused_tick_usage += tick_usage
				queue_node = queue_node.queue_next
				continue

			queue_node.ticks = MC_AVERAGE(queue_node.ticks, queue_node.paused_ticks)
			tick_usage += queue_node.paused_tick_usage

			queue_node.tick_usage = MC_AVERAGE_FAST(queue_node.tick_usage, tick_usage)

			queue_node.cost = MC_AVERAGE_FAST(queue_node.cost, TICK_DELTA_TO_MS(tick_usage))
			queue_node.paused_ticks = 0
			queue_node.paused_tick_usage = 0

			if (queue_node_flags & SS_BACKGROUND) // Update our running total.
				queue_priority_count_bg -= queue_node_priority

			else
				queue_priority_count -= queue_node_priority

			queue_node.last_fire = world.time
			queue_node.times_fired++

			if (queue_node_flags & SS_TICKER)
				queue_node.next_fire = world.time + (world.tick_lag * queue_node.wait)

			else if (queue_node_flags & SS_POST_FIRE_TIMING)
				queue_node.next_fire = world.time + queue_node.wait + (world.tick_lag * (queue_node.tick_overrun/100))

			else if (queue_node_flags & SS_KEEP_TIMING)
				queue_node.next_fire += queue_node.wait

			else
				queue_node.next_fire = queue_node.queued_time + queue_node.wait + (world.tick_lag * (queue_node.tick_overrun/100))

			queue_node.queued_time = 0

			// Remove from queue.
			queue_node.dequeue()

			queue_node = queue_node.queue_next

	. = TRUE

/**
 * Resets the queue, and all subsystems, while filtering out the subsystem lists called if any mc's queue procs runtime or exit improperly.
 *
 * Arguments:
 * * SSticker_SS - List of ticker subsystems to reset.
 * * runlevel_SS - List of runlevel subsystems to reset.
 */
/datum/controller/master/proc/SoftReset(list/SSticker_SS, list/runlevel_SS)
	. = FALSE
	log_world("MC: SoftReset called, resetting MC queue state.")
	if (!istype(subsystems) || !istype(SSticker_SS) || !istype(runlevel_SS))
		log_world("MC: SoftReset: Bad list contents: '[subsystems]' '[SSticker_SS]' '[runlevel_SS]'")
		return

	var/subsystemstocheck = subsystems + SSticker_SS
	for(var/I in runlevel_SS)
		subsystemstocheck |= I

	for (var/thing in subsystemstocheck)
		var/datum/controller/subsystem/SS = thing
		if (!SS || !istype(SS))
			// list(SS) is so if a list makes it in the subsystem list, we remove the list, not the contents
			subsystems -= list(SS)
			SSticker_SS -= list(SS)
			for(var/I in runlevel_SS)
				I -= list(SS)

			log_world("MC: SoftReset: Found bad entry in subsystem list, '[SS]'")
			continue

		if (SS.queue_next && !istype(SS.queue_next))
			log_world("MC: SoftReset: Found bad data in subsystem queue, queue_next = '[SS.queue_next]'")

		SS.queue_next = null
		if (SS.queue_prev && !istype(SS.queue_prev))
			log_world("MC: SoftReset: Found bad data in subsystem queue, queue_prev = '[SS.queue_prev]'")

		SS.queue_prev = null
		SS.queued_priority = 0
		SS.queued_time = 0
		SS.state = SS_IDLE
	if (queue_head && !istype(queue_head))
		log_world("MC: SoftReset: Found bad data in subsystem queue, queue_head = '[queue_head]'")

	queue_head = null
	if (queue_tail && !istype(queue_tail))
		log_world("MC: SoftReset: Found bad data in subsystem queue, queue_tail = '[queue_tail]'")

	queue_tail = null
	queue_priority_count = 0
	queue_priority_count_bg = 0
	log_world("MC: SoftReset: Finished.")
	. = TRUE


/datum/controller/master/stat_entry()
	return "(TickRate:[Master.processing]) (Iteration:[Master.iteration])"


/datum/controller/master/StartLoadingMap()
	// Disallow more than one map to load at once, multithreading it will just cause race conditions.
	while(map_loading)
		stoplag()

	for(var/S in subsystems)
		var/datum/controller/subsystem/SS = S
		SS.StartLoadingMap()

	map_loading = TRUE


/datum/controller/master/StopLoadingMap(bounds)
	map_loading = FALSE
	for(var/S in subsystems)
		var/datum/controller/subsystem/SS = S
		SS.StopLoadingMap()


/*
/datum/controller/master/proc/UpdateTickRate()
	if (!processing)
		return
	var/client_count = length(GLOB.clients)
	if (client_count < CONFIG_GET(number/mc_tick_rate/disable_high_pop_mc_mode_amount))
		processing = CONFIG_GET(number/mc_tick_rate/base_mc_tick_rate)
	else if (client_count > CONFIG_GET(number/mc_tick_rate/high_pop_mc_mode_amount))
		processing = CONFIG_GET(number/mc_tick_rate/high_pop_mc_tick_rate)
*/


/datum/controller/master/proc/OnConfigLoad()
	for (var/thing in subsystems)
		var/datum/controller/subsystem/SS = thing
		SS.OnConfigLoad()
