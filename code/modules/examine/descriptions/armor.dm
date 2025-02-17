
/obj/item/clothing/get_description_info()
	var/armor_stats = description_info + "\
	<br>"


	if(atom_flags & ALLOWINTERNALS)
		armor_stats += "It is airtight. \n"

	if(min_pressure_protection == 0)
		armor_stats += "Wearing this will protect you from the vacuum of space. \n"
	else if(min_pressure_protection != null)
		armor_stats += "Wearing this will protect you from low pressures, but not the vacuum of space. \n"

	if(max_pressure_protection != null)
		armor_stats += "Wearing this will protect you from high pressures. \n"

	if(clothing_flags & THICKMATERIAL)
		armor_stats += "The material is exceptionally thick. \n"

	if(max_heat_protection_temperature == FIRESUIT_MAX_HEAT_PROTECTION_TEMPERATURE)
		armor_stats += "It provides very good protection against fire and heat. \n"

	if(min_cold_protection_temperature == SPACE_SUIT_MIN_COLD_PROTECTION_TEMPERATURE)
		armor_stats += "It provides very good protection against very cold temperatures. \n"

	var/list/covers = list()
	var/list/slots = list()

	for(var/name in string_part_flags)
		if(body_cover_flags & string_part_flags[name])
			covers += name

	for(var/name in string_slot_flags)
		if(slot_flags & string_slot_flags[name])
			slots += name

	if(covers.len)
		armor_stats += "It covers the [english_list(covers)]. \n"

	if(slots.len)
		armor_stats += "It can be worn on your [english_list(slots)]. \n"

	return armor_stats
