@tool

extends Resource
class_name GrammarState

var rng = RandomNumberGenerator.new()
var gm = GrammarMesh.new()

# Grammar configuration
@export var grammar : Grammar:
	set(gr):
		gm.set_grammar_state(self)
		
		grammar = gr
		clear_state()
		
		if gr != null:
			initial_symbol = 0
		
		self.notify_property_list_changed()

var default_seed = "".num_uint64(rng.randi_range(0, 0x7FFFFFFFFFFF), 16, true)
@export var seed : String = default_seed:
	set(s):
		var u64 = s.substr(0, 12).hex_to_int()
		rng.seed = u64
		
		if auto_generate:
			self.generate_all()
			
	get:
		var str = "".num_uint64(rng.seed, 16, true).substr(0, 12)
		
		return str

@export var generations : int = 0:
	set(nog):
		if nog < 0:
			nog = 0
			
		generations = nog
		
		if auto_generate:
			self.generate_all()

@export var auto_generate : bool = true

var initial_symbol : int:
	set(i):
		initial_symbol = i
		
		if grammar != null:
			_initial_symbol2 = grammar.from_enum(i)
			

var initial_symbol_override : String:
	set(str):
		initial_symbol_override = str
		
			
		if grammar != null and grammar.has(str):
			_initial_symbol2 = str
			
		else:
			_initial_symbol2 = grammar.from_enum(initial_symbol)
			
var _initial_symbol2 : String:
	set(str):
		_initial_symbol2 = str
		initial_shape = grammar.get_shape(str)
		
		if auto_generate:
			self.generate_all()

var initial_shape : GrammarShape

# State
var shapes : Array[GrammarShape] = []
var terminals : Array[GrammarShape] = []

var generation_count = -1

func _get_property_list():
	var properties = []
	
	var property_usage = PROPERTY_USAGE_NO_EDITOR
	var hint_string = ""
	
	if self.grammar != null:
		property_usage = PROPERTY_USAGE_DEFAULT
		hint_string = self.grammar.get_hints()
	
	properties = []
	properties.append({
		"name": "initial_symbol",
		"type": TYPE_INT,
		"usage": property_usage,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": hint_string
	})

	return properties

func _add_terminal(terminal_shape):
	self.terminals.push_back(terminal_shape)
	
func _clear_terminals():
	self._terminals = []

func clear_state():
	self.shapes = []
	self.terminals = []
	self.generation_count = -1
	
	self.emit_changed()

func start():
	if self.grammar != null and initial_shape != null:
		self.shapes = [initial_shape]
		self.terminals = []
		self.generation_count = 0
		self.rng.state = 0
		
		return false
		
	else:
		self.clear_state()
		return true

func next_generation_no_signal():
	if self.generation_count == -1:
		if self.start():
			return
			
	if self.shapes.size() == 0:
		return
	
	var old_shape_names = []
	var new_shape_names = []
	var new_shapes = []
	for shape in self.shapes:
		old_shape_names.append(shape.symbol.text)
		
		# Get the rule
		var grammar_rule = shape.symbol.select_rule(self.rng)
		
		# No rules, keep the shape
		if grammar_rule == null:
			new_shapes.append(shape)
			
		else:
			var shapes = grammar_rule.fulfill(shape)
			
			new_shapes.append_array(shapes)
	
	# Split the new array between shapes and terminals
	self.shapes = []
	for shape in new_shapes:
		new_shape_names.append(shape.symbol.text)
		
		if shape.symbol.is_terminal():
			self._add_terminal(shape)
			
		else:
			self.shapes.push_back(shape)
			
	self.generation_count += 1
	
func next_generation():
	self.next_generation_no_signal()
	self.emit_changed()
	
func generate_all():
	self.nth_gen(self.generations)

func nth_gen(n=self.generations):
	self.start()
	for i in n:
		self.next_generation_no_signal()
		
	self.emit_changed()
	
func total_size():
	return self.shapes.size() + self.terminals.size()
	
func get_grammar_mesh() -> GrammarMesh:
	return self.gm
