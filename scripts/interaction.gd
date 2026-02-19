class_name interactable extends Node

@export var interaction_tut: Label

var parent

func _ready() -> void:
	parent = get_parent()
	connect_parent()

func in_range():
	print("focused")

func not_in_range():
	print("unfocused")

func interact():
	print("interacted")

func connect_parent():
	parent.add_user_signal("focused")
	parent.add_user_signal("unfocused")
	parent.add_user_signal("interacting")
	parent.connect("focused", Callable(self, "in_range"))
	parent.connect("unfocused", Callable(self, "not_in_range"))
	parent.connect("interacting", Callable(self, "interact"))
