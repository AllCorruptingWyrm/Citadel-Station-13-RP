/obj/projectile/change
	name = "bolt of change"
	icon_state = "ice_1"
	damage = 0
	damage_type = BURN
	nodamage = 1
	damage_flag = ARMOR_ENERGY

	combustion = FALSE

/obj/projectile/change/on_hit(var/atom/change)
	wabbajack(change)

/obj/projectile/change/proc/wabbajack(var/mob/M)
	if(istype(M, /mob/living) && M.stat != DEAD)
		if(M.transforming)
			return
		if(M.has_brain_worms())
			return //Borer stuff - RR

		if(istype(M, /mob/living/silicon/robot))
			var/mob/living/silicon/robot/Robot = M
			if(Robot.mmi)
				qdel(Robot.mmi)
		else
			M.drop_inventory(TRUE, TRUE, TRUE)

		var/mob/living/new_mob

		var/options = list("robot", "slime")
		for(var/t in SScharacters.all_species_names())
			options += t
		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			if(H.species)
				options -= H.species.name
		else if(isrobot(M))
			options -= "robot"
		else if(isslime(M))
			options -= "slime"

		var/randomize = pick(options)
		switch(randomize)
			if("robot")
				new_mob = new /mob/living/silicon/robot(M.loc)
				new_mob.gender = M.gender
				new_mob.invisibility = 0
				new_mob.job = "Cyborg"
				var/mob/living/silicon/robot/Robot = new_mob
				Robot.mmi = new /obj/item/mmi(new_mob)
				Robot.mmi.transfer_identity(M)	//Does not transfer key/client.
			if("slime")
				new_mob = new /mob/living/simple_mob/slime/xenobio(M.loc)
				new_mob.universal_speak = 1
			else
				var/mob/living/carbon/human/H
				if(ishuman(M))
					H = M
				else
					new_mob = new /mob/living/carbon/human(M.loc)
					H = new_mob

				if(M.gender == MALE)
					H.gender = MALE
					H.name = pick(GLOB.first_names_male)
				else if(M.gender == FEMALE)
					H.gender = FEMALE
					H.name = pick(GLOB.first_names_female)
				else
					H.gender = NEUTER
					H.name = pick(GLOB.first_names_female | GLOB.first_names_male)

				H.name += " [pick(GLOB.last_names)]"
				H.real_name = H.name

				H.set_species(randomize)
				H.universal_speak = 1
				var/datum/preferences/A = new() //Randomize appearance for the human
				A.randomize_appearance_and_body_for(H)

		if(new_mob)
			for (var/spell/S in M.spell_list)
				new_mob.add_spell(new S.type)

			new_mob.a_intent = "hurt"
			if(M.mind)
				M.mind.transfer_to(new_mob)
			else
				new_mob.key = M.key

			to_chat(new_mob, "<span class='warning'>Your form morphs into that of \a [lowertext(randomize)].</span>")

			qdel(M)
			return
		else
			to_chat(M, "<span class='warning'>Your form morphs into that of \a [lowertext(randomize)].</span>")
			return
