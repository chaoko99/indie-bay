//New distress beacon system.
//Distress responses below.
//Basically hacking this into the ERT system.
//Or not. Parts of this are copied verbatim from various code sources.

var/global/send_distress_team = 0
var/global/distress_team_type = null
var/global/picked_distress_call = null

#define HELPING_HAND 1
#define SOLGOV_ENFORCERS 2
#define RAIDERS 3
#define SYNDICATE_COMMANDOS 4
#define FRONTIER_HICKS 5

/datum/distress_call
	var/distress_name = "name" //What are we called?
	var/dispatch_message = "An encrypted signal from a nearby vessel has been detected. Decoding." //The response message.
	var/arrival_message = null //What do we state when we dock?
	var/objectives = null //What is the response team's objective?
	var/probability = 0 //How likely is this to happen?
	var/ship_name = null //What the ship is called.
	var/equipt_tag //Used for defining what they get on spawn.

/datum/distress_call/helping_hand
	distress_name = "Helping Hand"
	arrival_message = "This is the ISV Helping Hand. A boarding team is on it's way to assist. Please don't shoot us."
	probability = 20
	objectives = "Help the crew of the ship and defeat the antagonists."
	ship_name = "ISV Helping Hand"
	equipt_tag = HELPING_HAND

/datum/distress_call/solgov_enforcers
	distress_name = "Solgov Enforcers"
	arrival_message = "This is the SCGF Indomitable. Lay down your arms and prepare to be boarded. Your ship is now being returned to it's rightful owners."
	probability = 10
	objectives = "Reclaim the ship, for the glory of Solgov! Kill or detain anyone who resists your commands."
	ship_name = "SCGF Indomitable"
	equipt_tag = SOLGOV_ENFORCERS

/datum/distress_call/raiders
	distress_name = "Raiders"
	arrival_message = "Attention prey. You and all your possessions are now our personal property. Resist, and you will be disabled, boarded, your officers massacred, and your crew sold as slaves."
	probability = 10
	objectives = "Ransack the ship, and kidnap who you can."
	ship_name = "Unknown Vessel"
	equipt_tag = RAIDERS

/datum/distress_call/syndicate_strike
	distress_name = "Syndicate Striketeam"
	arrival_message = "This is the SMV God's Fist. Your ship and it's crew are now our property. Any resistance will be met with lethal force."
	probability = 10
	objectives = "Capture the ship. Kill anyone who resists. Enslave the crew."
	ship_name = "SMV God's Fist"
	equipt_tag = SYNDICATE_COMMANDOS

/datum/distress_call/frontier_hicks
	distress_name = "Frontier Hauler"
	arrival_message = "Howdy, fellers! Heard you's in some distress while we're passin' by! Folks look out for each other in these parts!"
	probability = 50
	objectives = "Help out the ship, but don't get killed doing it."
	ship_name = "IHV Wanderlust"
	equipt_tag = FRONTIER_HICKS

/datum/game_mode
	var/list/all_calls = list() //initialized at round start and stores the datums.
	var/picked_call = null //Which distress call is currently active

/datum/game_mode/proc/initialize_emergency_calls()
	if(all_calls.len) //It's already been set up.
		return

	var/list/total_calls = typesof(/datum/distress_call)
	if(!total_calls.len)
		return 0
	for(var/S in total_calls)
		var/datum/distress_call/C = new S()
		if(!C)	continue
		if(C.distress_name == "name") continue //The default parent, don't add it
		all_calls += C

/datum/game_mode/proc/get_random_call()
	var/chance = rand(1,100)
	var/add_prob = 0
	var/datum/distress_call/chosen_call

	for(var/datum/distress_call/E in all_calls) //Loop through all potential candidates
		if(chance >= E.probability + add_prob) //Tally up probabilities till we find which one we landed on
			add_prob += E.probability
			continue
		chosen_call = E //Our random chance found one.
		break

	if(!istype(chosen_call))
		return null
	else
		return chosen_call

/datum/game_mode/proc/setup_equipt() //Set up our equiptment tags.
	var/datum/distress_call/P
	P = picked_call
	distress_team_type = P.equipt_tag

/datum/game_mode/proc/show_join_message()
	for(var/mob/M in world)
		if(isghost(usr) || isnewplayer(usr))
			if(M.client)
				to_chat(M, "<font size='3'><span class='danger'>An emergency beacon has been activated. Use the <B>Join Distress Team</b> verb, <B>IC tab</b>, to join!</span></font>")


/client/verb/JoinDistressTeam()

	set name = "Join Distress Response Team"
	set category = "IC"

	if(!MayRespawn(1))
		to_chat(usr, "<span class='warning'>You cannot join the distress team at this time.</span>")
		return

	if(isghost(usr) || isnewplayer(usr))
		if(!send_distress_team)
			to_chat(usr, "No distress response team is currently being sent.")
			return
		if(jobban_isbanned(usr, MODE_DISTRESS) || jobban_isbanned(usr, "Security Officer"))
			to_chat(usr, "<span class='danger'>You are jobbanned from the distress reponse team!</span>")
			return
		if(distress_response.current_antagonists.len >= ert.hard_cap)
			to_chat(usr, "The distress response team is already full!")
			return
		distress_response.create_default(usr)
	else
		to_chat(usr, "You need to be an observer or new player to use this.")

/datum/game_mode/proc/trigger_distress_team()
	//DEBUG
	if(send_distress_team)
		return
	var/datum/distress_call/P
	picked_call = get_random_call()
	setup_equipt()
	P = picked_call
	command_announcement.Announce("[P.arrival_message]", "[P.ship_name]")
	distress_team_type = P.equipt_tag
	evacuation_controller.add_can_call_predicate(new/datum/evacuation_predicate/ert())

	can_call_ert = 0 // Only one call per round, gentleman.
	send_distress_team = 1
	distress_equipment_spawn()
	show_join_message()
	spawn(600 * 5)
		send_distress_team = 0 // Can no longer join the ERT.

//Variable equiptment spawning handled below

/datum/game_mode/proc/distress_equipment_spawn()
	var/obj/effect/landmark/L
	for(L in world)
		if(L.name == "distress_armor")
			switch(distress_team_type)
				if(1)
					for(var/i = 1 to 3)
						new /obj/item/clothing/suit/armor/pcarrier/medium(get_turf(L))
						new /obj/item/clothing/head/helmet(get_turf(L))
						new /obj/item/clothing/mask/gas(get_turf(L))
				if(2)
					for(var/i = 1 to 3)
						new /obj/item/clothing/suit/armor/vest/ert(get_turf(L))
						new /obj/item/clothing/head/helmet/ert(get_turf(L))
						new /obj/item/clothing/mask/gas(get_turf(L))
				if(3)
					for(var/i = 1 to 3)
						new /obj/item/clothing/suit/armor/pcarrier/medium(get_turf(L))
						new /obj/item/clothing/suit/pirate(get_turf(L))
						new /obj/item/clothing/head/pirate(get_turf(L))
						new /obj/item/clothing/mask/bandana/red(get_turf(L))
				if(4)
					for(var/i = 1 to 3)
						new /obj/item/clothing/suit/armor/pcarrier/merc(get_turf(L))
						new /obj/item/clothing/head/helmet/merc(get_turf(L))
						new /obj/item/clothing/mask/balaclava(get_turf(L))
				if(5)
					for(var/i = 1 to 3)
						new /obj/item/clothing/suit/armor/vest/old(get_turf(L))
						new /obj/item/clothing/head/helmet(get_turf(L))
						new /obj/item/clothing/mask/breath(get_turf(L))
		if(L.name == "distress_voidsuit")
			switch(distress_team_type)
				if(1)
					for(var/i = 1 to 2)
						new /obj/item/weapon/rig/eva/equipped(get_turf(L))
						new /obj/item/weapon/rig/industrial(get_turf(L))
				if(2)
					for(var/i = 1 to 3)
						new /obj/item/weapon/rig/ert(get_turf(L))
				if(3)
					for(var/i = 1 to 2)
						new /obj/item/weapon/rig/eva/equipped(get_turf(L))
						new /obj/item/weapon/rig/industrial(get_turf(L))
				if(4)
					for(var/i = 1 to 3)
						new /obj/item/weapon/rig/merc/empty(get_turf(L))
					new /obj/item/weapon/rig/merc/heavy/empty(get_turf(L))
				if(5)
					for(var/i = 1 to 3)
						new /obj/item/weapon/rig/eva(get_turf(L))
		if(L.name == "distress_weapon")
			switch(distress_team_type)
				if(1)
					for(var/i = 1 to 3)
						new /obj/item/weapon/gun/energy/gun(get_turf(L))
						new /obj/item/weapon/gun/energy/gun/small(get_turf(L))
						new /obj/item/weapon/gun/projectile/automatic/wt550(get_turf(L))
				if(2)
					for(var/i = 1 to 3)
						new /obj/item/weapon/gun/projectile/sec/wood(get_turf(L))
						new /obj/item/weapon/gun/energy/gun/nuclear(get_turf(L))
						new /obj/item/weapon/gun/projectile/shotgun/pump/combat(get_turf(L))
				if(3)
					for(var/i = 1 to 3)
						new /obj/item/weapon/gun/projectile/pirate(get_turf(L))
						new /obj/item/weapon/gun/energy/gun/small(get_turf(L))
						new /obj/item/weapon/gun/projectile/automatic/machine_pistol(get_turf(L))
				if(4)
					for(var/i = 1 to 3)
						new /obj/item/weapon/gun/energy/gun(get_turf(L))
						new /obj/item/weapon/gun/projectile/automatic/c20r(get_turf(L))
						new /obj/item/weapon/gun/projectile/revolver/mateba(get_turf(L))
				if(5)
					for(var/i = 1 to 3)
						new /obj/item/weapon/gun/projectile/automatic/sts35(get_turf(L))
						new /obj/item/weapon/gun/energy/gun/small(get_turf(L))
						new /obj/item/weapon/gun/projectile/shotgun/doublebarrel/sawn(get_turf(L))




