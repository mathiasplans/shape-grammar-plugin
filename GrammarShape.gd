@tool

extends RefCounted
class_name GrammarShape

var symbol = null
var vertices = []

# Persistant:
# * symbol
# * vertices

func save():
	return [symbol.text, self.vertices]
	
func pack():
	return self.save()
	
static func from_data(data, symbol_map):
	return GrammarShape.new(symbol_map[data[0]], data[1])
	
static func from_packed(p, symbol_map):
	return from_data(p, symbol_map)
	
func serialize():
	var data = PackedByteArray()
	
	var s = 4 + vertices.size() * 3 * 4
	s = snappedi(s + 1.5, 4)
	data.resize(s)
	
	var i = 0
	data.encode_u32(i, data.size())
	i += 4
	
	for vertex in self.vertices:
		for j in 3:
			data.encode_float(i, vertex[j])
			i += 4
			
	return data

func _init(_symbol, _vertices):
	self.symbol = _symbol
	self.vertices = _vertices
