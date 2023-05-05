@tool

extends ArrayMesh
class_name GrammarMesh

@export var grammar_state : GrammarState:
	set(gs):
		if self.grammar_state != gs:
			if grammar_state != null:
				grammar_state.changed.disconnect(self._on_gs_changed)
			
			grammar_state = gs
			
			if grammar_state != null:
				grammar_state.changed.connect(self._on_gs_changed)

func _on_gs_changed():
	self.update_mesh()

func set_grammar_state(gs : GrammarState):
	self.grammar_state = gs

# Mesh generation functions
static func calculate_normal_from_points(p1, p2, p3):
	return (p1 - p2).cross(p3 - p2).normalized()
	
static func _insert_brep(points, face, uv, st: SurfaceTool, color: Color):
	if color == null:
		color = Color(1, 1, 1, 1)
	
	var normal = calculate_normal_from_points(
			points[face[0]],
			points[face[1]],
			points[face[2]]
	)
	
	# Triangularisation
	# NOTE: Only works when the face is convex
	for i in face.size() - 2:
		var i0 = face[0]
		var i1 = face[i + 1]
		var i2 = face[i + 2]
		
		st.set_normal(normal)
		st.set_color(color)
		st.set_uv(uv[0])	
		st.add_vertex(points[i0])
		st.set_uv(uv[i + 1])
		st.add_vertex(points[i1])
		st.set_uv(uv[i + 2])
		st.add_vertex(points[i2])

	st.set_color(Color(1, 1, 1, 1))

static func brep_to_mesh(points, faces, st, uvs=null, color=Color(1, 1, 1, 1)):
	for face_i in faces.size():
		var face = faces[face_i]
			
		var uv = []
		if uvs == null:
			for i in face.size():
				uv.push_back(Vector2(0, 0))
			
		else:
			uv = uvs[face_i]
		
		_insert_brep(points, face, uv, st, color)
		
func update_mesh(color=Color(1, 1, 1, 1)):
	if self.grammar_state.shapes.size() + self.grammar_state.terminals.size() == 0:
		return null
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for shape in self.grammar_state.shapes:
		brep_to_mesh(shape.vertices, shape.symbol.faces, st, null, color)
		
	for shape in self.grammar_state.terminals:
		brep_to_mesh(shape.vertices, shape.symbol.faces, st, null, color)
		
	self.clear_surfaces()
	self.clear_blend_shapes()
	st.commit(self)
