extends Node2D

var ALL_CARDS = [
	make_card("Dragon", 2, 5, 7, 6, 3),
	make_card("Knight", 5, 5, 5, 5, 2),
	make_card("Goblin", 1, 2, 8, 9, 2),
	make_card("Elf", 8, 9, 1, 2, 3),
	make_card("Commander", 8, 3, 6, 3, 2),
	make_card("Cactrot", 7, 3, 7, 3, 2),
	make_card("Pyro", 1, 9, 1, 9, 1),
	make_card("Queen", 5, 6, 4, 6, 2),
	make_card("King", 6, 4, 6, 4, 2),
	make_card("Ballista", 8, 8, 2, 2, 3)
]

func make_card(name, up, right, down, left, life_points):
	return { "name": name, "up": up, "right": right, "down": down, "left": left, "lp": life_points }