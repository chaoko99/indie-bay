var/datum/antagonist/distress_response/distress_response

/datum/antagonist/distress_response
	id = MODE_DISTRESS
	role_text = "Distress Responder"
	role_text_plural = "Distress Responders"
	welcome_text = "As member of the Distress Responders, you answer to your leader and the admins."
	antag_text = "You are a potential antagonist! Pay attention to the stated text and your mission."
	leader_welcome_text = "You shouldn't see this"
	landmark_id = "Response Team"
	id_type = /obj/item/weapon/card/id
	var/antag_objective = null //We're special so this gets handled here!

	flags = ANTAG_OVERRIDE_JOB | ANTAG_SET_APPEARANCE | ANTAG_HAS_LEADER | ANTAG_CHOOSE_NAME | ANTAG_RANDOM_EXCEPTED
	antaghud_indicator = "hudloyalist"

	hard_cap = 4
	hard_cap_round = 4
	initial_spawn_req = 4
	initial_spawn_target = 4
	show_objectives_on_creation = 1 //we are not antagonists, we do not need the antagonist shpiel/objectives

/datum/antagonist/distress_response/create_default(var/mob/source)

	var/mob/living/carbon/human/M = ..()
	if(istype(M)) M.age = rand(25,45)

/datum/antagonist/distress_response/New()
	..()
	leader_welcome_text = "As the leader of the Distress response team, you should follow your stated objectives. Either help or harm the crew - your choice."
	distress_response = src

/datum/antagonist/distress_response/create_global_objectives()
	var/datum/distress_call/D
	D = ticker.mode.picked_call
	antag_objective = D.objectives
	if(!..())
		return 0
	global_objectives = list()
	global_objectives += D.objectives
	return 1

/datum/antagonist/distress_response/greet(var/datum/mind/player)
	if(!..())
		return
	to_chat(player.current, "There's been a distress beacon launched from the ship. Go see what's going on, and maybe take advantage.")
	to_chat(player.current, "You should first gear up and discuss a plan with your team. More members may be joining, don't move out before you're ready.")
	to_chat(player.current, "Your team's current objective is: [antag_objective]")

/datum/antagonist/distress_response/equip(var/mob/living/carbon/human/player)
	var/datum/distress_call/D
	D = ticker.mode.picked_call
	switch(D.equipt_tag)
		if(1)
			player.equip_to_slot_or_del(new /obj/item/device/radio/headset/ert(src), slot_l_ear)
			player.equip_to_slot_or_del(new /obj/item/clothing/under/hazard(src), slot_w_uniform)
			player.equip_to_slot_or_del(new /obj/item/clothing/shoes/magboots(src), slot_shoes)
			player.equip_to_slot_or_del(new /obj/item/clothing/gloves/thick(src), slot_gloves)
			player.equip_to_slot_or_del(new /obj/item/clothing/glasses/welding(src), slot_glasses)
		if(2)
			player.equip_to_slot_or_del(new /obj/item/device/radio/headset/ert(src), slot_l_ear)
			player.equip_to_slot_or_del(new /obj/item/clothing/under/ert(src), slot_w_uniform)
			player.equip_to_slot_or_del(new /obj/item/clothing/shoes/swat(src), slot_shoes)
			player.equip_to_slot_or_del(new /obj/item/clothing/gloves/thick/swat(src), slot_gloves)
			player.equip_to_slot_or_del(new /obj/item/clothing/glasses/sunglasses(src), slot_glasses)
		if(3)
			player.equip_to_slot_or_del(new /obj/item/device/radio/headset/raider(src), slot_l_ear)
			player.equip_to_slot_or_del(new /obj/item/clothing/under/pirate(src), slot_w_uniform)
			player.equip_to_slot_or_del(new /obj/item/clothing/shoes/leather(src), slot_shoes)
			player.equip_to_slot_or_del(new /obj/item/clothing/gloves/thick/swat(src), slot_gloves)
			player.equip_to_slot_or_del(new /obj/item/clothing/glasses/eyepatch(src), slot_glasses)
		if(4)
			player.equip_to_slot_or_del(new /obj/item/device/radio/headset/syndicate(src), slot_l_ear)
			player.equip_to_slot_or_del(new /obj/item/clothing/under/syndicate/tacticool(src), slot_w_uniform)
			player.equip_to_slot_or_del(new /obj/item/clothing/shoes/swat(src), slot_shoes)
			player.equip_to_slot_or_del(new /obj/item/clothing/gloves/thick/swat(src), slot_gloves)
			player.equip_to_slot_or_del(new /obj/item/clothing/glasses/thermal(src), slot_glasses)
		if(5)
			player.equip_to_slot_or_del(new /obj/item/device/radio/headset/ert(src), slot_l_ear)
			player.equip_to_slot_or_del(new /obj/item/clothing/under/overalls(src), slot_w_uniform)
			player.equip_to_slot_or_del(new /obj/item/clothing/shoes/workboots(src), slot_shoes)
			player.equip_to_slot_or_del(new /obj/item/clothing/gloves/duty(src), slot_gloves)
			player.equip_to_slot_or_del(new /obj/item/clothing/glasses/material(src), slot_glasses)
	create_id(role_text, player)
	return 1
