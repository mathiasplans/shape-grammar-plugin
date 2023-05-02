@tool

extends MeshInstance3D
class_name GrammarInstance3D

@export var grammar_state : GrammarState:
	set(gs):
		grammar_state = gs
		next_generation
		
		if gs != null:
			generate_mesh()
			gs.change_cb = generate_mesh
		
		else:
			self.mesh = null
		
@export var generation_count : int = 5:
	set(i):
		if i < 0:
			i = 0
			
		generation_count = i
		
		generate_mesh()
		
@export var auto_generate : bool = true

func generate_mesh():
	self.nth_gen(self.generation_count)

func nth_gen(n=self.generation_count):
	if self.grammar_state != null:
		self.restart()
		self.next_generation(n)
		self.update_mesh()
	
func restart():
	if self.grammar_state != null:
		self.grammar_state.start()
	
func next_generation(count=1):
	if self.grammar_state != null:
		for i in count:
			self.grammar_state.next_generation()

func get_grammar_mesh():
	if self.grammar_state != null:
		return gs_to_mesh(self.grammar_state)
		
func update_mesh():
	var new_mesh = self.get_grammar_mesh()
	self.mesh = new_mesh

func _ready():
	if Engine.is_editor_hint() or self.auto_generate:
		nth_gen(generation_count)

# Mesh functions
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
		
static func gs_to_mesh(grammar_state, color=Color(1, 1, 1, 1)):
	if grammar_state.shapes.size() + grammar_state.terminals.size() == 0:
		return null
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for shape in grammar_state.shapes:
		brep_to_mesh(shape.vertices, shape.symbol.faces, st, null, color)
		
	for shape in grammar_state.terminals:
		brep_to_mesh(shape.vertices, shape.symbol.faces, st, null, color)
		
	return st.commit()
