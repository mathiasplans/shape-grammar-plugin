@tool

extends MeshInstance3D
class_name GrammarInstance3D

@export var grammar_state : GrammarState:
	set(gs):
		grammar_state = gs
		
		if gs != null:
			gs.changed.connect(self.update_mesh)
			self.update_mesh()
		
		else:
			self.mesh = null

func update_mesh():
	if self.grammar_state != null:
		var new_mesh = self.grammar_state.get_grammar_mesh()
		self.mesh = new_mesh
