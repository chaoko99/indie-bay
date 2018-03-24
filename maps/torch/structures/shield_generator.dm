//This is janky to an extreme. -k22
/obj/machinery/power/shield_generator/big
	name = "high powered shield generator"
	icon = 'maps/torch/icons/obj/bsg.dmi'
	icon_state = "bsg_off"
	var/id = null
	var/glowy = null
	var/linked = 0
	var/list/things_in_range = list()
	var/list/glowies_in_range = list()

/obj/machinery/power/shield_generator/big/update_icon()
	if(running)
		icon_state = "bsg_on"
	else
		icon_state = "bsg_off"

/obj/machinery/power/shield_generator/big/New()
	..()
	component_parts = list()
	component_parts += new /obj/item/weapon/circuitboard/shield_generator(src)
	component_parts += new /obj/item/weapon/stock_parts/capacitor(src)			// Capacitor. Improves shield mitigation when better part is used.
	component_parts += new /obj/item/weapon/stock_parts/micro_laser(src)
	component_parts += new /obj/item/weapon/smes_coil(src)						// SMES coil. Improves maximal shield energy capacity.
	component_parts += new /obj/item/weapon/stock_parts/console_screen(src)
	RefreshParts()
	connect_to_network()
	wires = new(src)
	glow_add()
	mode_list = list()
	for(var/st in subtypesof(/datum/shield_mode/))
		var/datum/shield_mode/SM = new st()
		mode_list.Add(SM)

/obj/structure/shield_generator_blocker
	density = 1
	icon = null

/obj/structure/shield_glowy
	name = null
	light_range = 8
	light_power = 8
	light_color = "#19e5c3"
	icon = 'maps/torch/icons/obj/shieldglowy.dmi'
	icon_state = null
	var/id = null
	var/linked = 0

/obj/machinery/power/shield_generator/big/proc/glow_add()
	if(src.linked)
		return
	var/list/things_in_range = range(3, src)
	var/obj/structure/shield_glowy/G
	for (G in things_in_range)
		glowies_in_range.Add(G)
	for (G in glowies_in_range)
		if(G.id == src.id)
			src.glowy = G
			G.linked = 1
			src.linked = 1
			set_light(8,8)
			G.icon_state = "activated"
			G.light_color = "#0cf2cf"
			G.layer = EFFECTS_LAYER
	return

/obj/machinery/power/shield_generator/big/Process()
	upkeep_power_usage = 0
	power_usage = 0
	glow_add()
	if(offline_for)
		offline_for = max(0, offline_for - 1)
	// We're turned off.
	if(!running)
		return
	// We are shutting down, therefore our stored energy disperses faster than usual.
	else if(running == SHIELD_DISCHARGING)
		current_energy -= SHIELD_SHUTDOWN_DISPERSION_RATE

	mitigation_em = between(0, mitigation_em - MITIGATION_LOSS_PASSIVE, mitigation_max)
	mitigation_heat = between(0, mitigation_heat - MITIGATION_LOSS_PASSIVE, mitigation_max)
	mitigation_physical = between(0, mitigation_physical - MITIGATION_LOSS_PASSIVE, mitigation_max)

	upkeep_power_usage = round((field_segments.len - damaged_segments.len) * ENERGY_UPKEEP_PER_TILE * upkeep_multiplier)

	if(powernet && (running == SHIELD_RUNNING) && !input_cut)
		var/energy_buffer = 0
		energy_buffer = draw_power(min(upkeep_power_usage, input_cap))
		power_usage += round(energy_buffer)

		if(energy_buffer < upkeep_power_usage)
			current_energy -= round(upkeep_power_usage - energy_buffer)	// If we don't have enough energy from the grid, take it from the internal battery instead.

		// Now try to recharge our internal energy.
		var/energy_to_demand
		if(input_cap)
			energy_to_demand = between(0, max_energy - current_energy, input_cap - upkeep_power_usage)
		else
			energy_to_demand = max(0, max_energy - current_energy)
		energy_buffer = draw_power(energy_to_demand)
		power_usage += energy_buffer
		current_energy += round(energy_buffer)
	else
		current_energy -= round(upkeep_power_usage)	// We are shutting down, or we lack external power connection. Use energy from internal source instead.

	if(current_energy <= 0)
		energy_failure()

	if(!overloaded)
		for(var/obj/effect/shield/S in damaged_segments)
			S.regenerate()
	else if (field_integrity() > 25)
		overloaded = 0
