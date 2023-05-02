@tool

extends Resource
class_name Grammar

var symbols : Array[GrammarSymbol] = []
var shapes : Array[GrammarShape] = []

var text_to_symbol = {}
var text_to_shape = {}

func build_dicts(symbol_map=null, shape_map=null):
	if symbol_map == null:
		self.text_to_symbol = {}
		
	else:
		self.text_to_symbol = symbol_map
		
	if shape_map == null:
		self.text_to_shape = {}
		
	else:
		self.text_to_shape = shape_map
	
	for i in self.symbols.size():
		var sym = self.symbols[i]
		var sha = self.shapes[i]
		
		var sym_name = sym.text
		
		if symbol_map == null:
			self.text_to_symbol[sym_name] = sym
			
		if shape_map == null:
			self.text_to_shape[sym_name] = sha

func set_symbols_shapes(syms : Array[GrammarSymbol], shaps: Array[GrammarShape], symbol_map=null, shape_map=null):
	self.symbols = syms
	self.shapes = shaps

	self.build_dicts(symbol_map, shape_map)
	
func pack():
	var syms = []
	for symbol in self.symbols:
		syms.append(symbol.pack())
		
	var shaps = []
	for shape in self.shapes:
		shaps.append(shape.pack())
		
	return [syms, shaps]
	
func unpack(p):
	var syms = p[0]
	var shaps = p[1]
	
	var real_syms : Array[GrammarSymbol]
	var real_shaps : Array[GrammarShape]
	
	var symbol_map = {}
	
	for i in syms.size():
		var sym = GrammarSymbol.from_packed(syms[i])
		var sym_text = sym.text
		symbol_map[sym_text] = sym
		
		real_syms.append(sym)
		
	for i in syms.size():
		var sha = GrammarShape.from_packed(shaps[i], symbol_map)
		real_shaps.append(sha)
		
		# Rules can now be generated and linked with symbols
		real_syms[i].unpack_rules(syms[i], symbol_map)
	
	self.set_symbols_shapes(real_syms, real_shaps, symbol_map)

func get_shape(str: String) -> GrammarShape:
	return self.text_to_shape[str]
	
func get_symbols() -> PackedStringArray:
	return self.text_to_symbol.keys()
	
func get_hints() -> String:
	return ",".join(self.get_symbols())

func from_enum(index: int) -> String:
	return self.get_symbols()[index]
	
func has(sym_name : String) -> bool:
	return self.text_to_symbol.has(sym_name)
