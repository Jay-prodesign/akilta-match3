class_name Match3SplashScreen
extends Control

signal continue_requested

@onready var enter_button: Button = $Layout/Enter

func _ready() -> void:
	enter_button.pressed.connect(func(): continue_requested.emit())
