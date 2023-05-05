@tool

extends MeshInstance3D
class_name GrammarInstance3D

@export var grammar_state : GrammarState:
	set(gs):
		grammar_state = gs
		grammar_mesh = gs.get_grammar_mesh()
		
@export var grammar_mesh : GrammarMesh:
	set(gm):
		grammar_mesh = gm
		self.mesh = gm
