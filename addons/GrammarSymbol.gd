@tool

extends RefCounted
class_name GrammarSymbol

var id = -1
var text = ""

var nr_of_vertices = 0
var faces = []
var terminal = true

var rules = {}
var rule_weigths = {}
var rule_weights_sum = 0

var rng = RandomNumberGenerator.new()

func save():
	return [id, text, nr_of_vertices, faces, terminal]
	
func l(data):
	self.id = data[0]
	self.text = data[1]
	self.nr_of_vertices = data[2]
	self.faces = data[3]
	self.terminal = data[4]
	
func pack():
	var sym_data = self.save()
	
	var rule_indices = []
	var rule_array = []
	for rule_i in self.rules:
		var rule = self.rules[rule_i]
		
		rule_indices.append(rule_i)
		rule_array.append(rule.pack())
		
	return [sym_data, rule_indices, rule_array]
		
static func from_data(data):
	var new_sym = GrammarSymbol.new(data[2], data[3], data[4])
	new_sym.id = data[0]
	new_sym.text = data[1]
	
	return new_sym
	
static func from_packed(p):
	var gs = from_data(p[0])
		
	return gs
	
func unpack_rules(p, symbol_map):	
	var rule_array = p[2]
	for i in rule_array.size():
		var rule_packed = rule_array[i]
		# This adds the rule to the symbol automatically as well
		GrammarRule.from_packed(rule_packed, self, symbol_map)
	
func serialize():
	# Sizes
	var data = PackedByteArray()
	data.resize(2)
	data.encode_u16(0, self.nr_of_vertices)
	data.append(text.length())
	data.append(self.rules.size())
	data.append(self.faces.size())
	data.append(self.terminal)
	
	var total_size = 0
	for face in self.faces:
		total_size += face.size()
		data.append(face.size())
		
	# Faces
	var i = data.size()
	i = snappedi(i + 1.5, 4)
	data.resize(i + total_size * 2)
	for face in self.faces:
		for vi in face:
			data.encode_u16(i, vi)
			i += 2
	
	data.append_array(self.text.to_utf8_buffer())
	
	# Pad
	var new_size = snappedi(data.size() + 5.5, 4)
	
	if new_size != data.size():
		data.resize(new_size)
	
	return data
	
func _init(_nr_of_verts,_faces,_terminal=true):
	self.nr_of_vertices = _nr_of_verts
	self.faces = _faces.duplicate(true)
	self.terminal = _terminal
	
	self.set_seed(100)

func has_same_topology_as(other):
	return self.nr_of_vertices == other.nr_of_vertices and self.faces == other.faces
	
func can_be_assigned_to(poly):
	return self.nr_of_vertices == poly.vertices.size() and self.faces == poly.faces

func is_terminal():
	return self.rules.size() == 0
	
func set_seed(_seed):
	self.rng.seed = _seed
	self.rng.state = 100
	
func add_rule(index, rule, weight=1):
	# Remove the old version of the rule if it exists
	self.remove_rule(index)
	
	self.rules[index] = rule
	self.rule_weigths[index] = weight
	self.rule_weights_sum += weight
	
func update_rule(index, rule, weight=1):
	self.add_rule(index, rule, weight)

func remove_rule(index):
	if self.rule_weigths.has(index):
		self.rule_weights_sum -= self.rule_weigths[index]
	
	self.rules.erase(index)
	self.rule_weigths.erase(index)
	
func get_rule(index):
	return self.rules[index]
	
# Selects rule randomly
func select_rule():
	var random_tresh = self.rng.randf_range(0, self.rule_weights_sum)
		
	var keys = self.rules.keys()
	var weight = 0
	for key in keys:	
		weight += self.rule_weigths[key]
		
		if weight >= random_tresh:
			return self.rules[key]
