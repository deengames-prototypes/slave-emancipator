extends Node

const MAX_VALUE = 6 # on spawn, not from upgrades
const UNIVERSE_SIZE = 50 # 50 cards in all
const PLAYER_DECK_SIZE = 20
const PLAYER_HAND_SIZE = 8
const NUM_NPCS = 5
const BATTLES_TO_LEVEL_UP = 2 # unused
const POINTS_PER_LEVEL_UP = 3 # unused

const CARD_WIDTH = 64
const CARD_HEIGHT = 84

var TYPES = ["Triangle", "Circle", "Square"]

var all_cards = []
var player_deck = []
var player_hand = [] # subset of player deck
var npc_decks = [] # array of arrays

# poor excuse for non-string type checking
var player
# shared between NPC and CoreGameScene
var current_npc_deck
var npc_fighting = -1
var npcs_beaten = []

var battles_until_next_level_up = BATTLES_TO_LEVEL_UP
var stats_points = 0

var map_data = null # array of NPC data, saved/loaded

func _ready():
	randomize()
	
	for i in range(UNIVERSE_SIZE):
		# Dupes are OK. Don't really care.
		# [1..max]
		var defense = (randi() % MAX_VALUE) + 1
		
		var four_values = []
		for i in range(4):
			four_values.append((randi() % MAX_VALUE) + 1)
		
		var affinity = TYPES[randi() % len(TYPES)]
		var card = {"defense": defense, "affinity": affinity, "four_values": four_values}
		all_cards.append(card)
		
	for i in range(NUM_NPCS):
		var deck = []
		
		for j in range(8):
		# dupes are fine
			var next = all_cards[randi() % len(all_cards)]
			next = parse_json(to_json(next)) # cheap way to copy it
			deck.append(next)
			
		# For NPC #n, upgrade n cards by +1. Easy breezy.
		# Not guaranteed to give linear difficulty. Meh.
		for j in range(i + 1):
			var random_card = deck[randi() % len(deck)]
			random_card.defense += 1
			
		npc_decks.append(deck)
	
	for i in range(PLAYER_DECK_SIZE):
		var next = all_cards[randi() % len(all_cards)]
		next = parse_json(to_json(next)) # cheap way to copy it
		player_deck.append(next)
	
	for i in range(PLAYER_HAND_SIZE):
		player_hand.append(player_deck[i])

# attacker_card => BoardTile
# attacker_coordinates => [x, y]
# defender_card => { "defense": 3, ... }
# defender_coordinates => [x, y]
func calculate_damage(attacker_card, attacker_coordinates, defender_card, defender_coordinates):
	var attack_value = 0
	var defend_value = 0
		
	if Features.FOUR_DIRECTIONAL_CARDS:
		# assume attacker and defender are adjacent. If not, this will collapse.
		var a_x = attacker_coordinates[0]
		var a_y = attacker_coordinates[1]
		var d_x = defender_coordinates[0]
		var d_y = defender_coordinates[1]
		
		if a_x == d_x:
			# vertically adjacent.
			if a_y > d_y:
				attack_value = attacker_card.four_values[0]
				defend_value = defender_card.four_values[3]
			elif a_y < d_y:
				attack_value = attacker_card.four_values[3]
				defend_value = defender_card.four_values[0]
		elif a_y == d_y:
			# horizontally adjacent
			if a_x > d_x:
				attack_value = attacker_card.four_values[1]
				defend_value = defender_card.four_values[2]
			elif a_x < d_x:
				attack_value = attacker_card.four_values[2]
				defend_value = defender_card.four_values[1]
	else:
		attack_value = attacker_card.defense
		defend_value = defender_card.defense
	
	var damage_multiplier = affinity_compare(attacker_card.affinity, defender_card.affinity)
	var raw_damage = (attack_value * damage_multiplier) - defend_value
	return max(raw_damage, 0)
	
func affinity_compare(attack_affinity, defend_affinity):
	if attack_affinity == defend_affinity: return 1 # 1x = normal
	
	if (attack_affinity == "Triangle" and defend_affinity == "Circle") or \
	(attack_affinity == "Circle" and defend_affinity == "Square") or \
	(attack_affinity == "Square" and defend_affinity == "Triangle"):
		return 2 # 2x = critical
	
	return 1 # 1x: weak