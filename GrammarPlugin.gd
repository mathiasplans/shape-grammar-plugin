@tool

extends EditorPlugin

func _enter_tree():
	var a = Grammar.new()
	# Initialization of the plugin goes here.
	add_custom_type("GrammarInstance3D", "MeshInstance3D", preload("GrammarInstance3D.gd"), preload("gm_icon.svg"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("GrammarMesh")
