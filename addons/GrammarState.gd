@tool

extends Resource
class_name GrammarState

# Grammar configuration
@export var grammar : Grammar:
	set(gr):
		grammar = gr
		clear_state()
		
		if gr != null:
			initial_symbol = 0
		
		self.notify_property_list_changed()
		
		if change_cb != null:
			change_cb.call()

var initial_symbol : int:
	set(i):
		initial_symbol = i
		
		if grammar != null:
			_initial_symbol2 = grammar.from_enum(i)
			
		#if change_cb != null:
		#	change_cb.call()

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

var initial_shape : GrammarShape

# State
var shapes : Array[GrammarShape] = []
var terminals : Array[GrammarShape] = []

var generations = -1

var change_cb

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
	self.generations = -1

func start():
	if self.grammar != null and initial_shape != null:
		self.shapes = [initial_shape]
		self.terminals = []
		self.generations = 0
		
		return false
		
	else:
		self.clear_state()
		return true
	
# Fulfill a grammar
func next_generation():
	if self.generations == -1:
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
		var grammar_rule = shape.symbol.select_rule()
		
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
			
	self.generations += 1
	
func total_size():
	return self.shapes.size() + self.terminals.size()
