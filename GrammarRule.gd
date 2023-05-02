@tool

extends RefCounted
class_name GrammarRule

class VirtualVertex:
	var from
	var to
	var type
	
	enum {FIRST, INTERPOLATE}
	
	func _init(_from,_to):
		self.from = _from
		self.to = _to
		
	func create_vertex(_vertex_array):
		pass
		
	func pack():
		return self.from | self.to << 16 | self.type << 32
		
	func to_string():
		return "%d %d %d" % [from, to, type]
		
class FirstVertex:
	extends VirtualVertex
	
	func _init(_from):
		super(_from, -1)
		self.type = VirtualVertex.FIRST
		pass
		
	func create_vertex(vertex_array):
		return vertex_array[self.from]
		
	func to_string():
		return "%d %d" % [from, type]
		
class InterpolateVertex:
	extends VirtualVertex
	var coef
	
	func _init(_from, _to, _coef):
		super(_from, _to)
		self.coef = _coef
		self.type = VirtualVertex.INTERPOLATE
		
	func pack():
		var p = super.pack()
		var b = p
		var a = int(((1 << 28) - 1))
		var val = int(((1 << 28) - 1) * self.coef)
		p = p | int(((1 << 28) - 1) * self.coef) << 36
		return p
		
	func create_vertex(vertex_array):
		var other_coef = 1 - self.coef
		return vertex_array[self.from] * other_coef + vertex_array[self.to] * self.coef
		
	func to_string():
		return "%d %d %d %d" % [from, to, type, coef]
		
static func unpack_vv(p):
	var pba = PackedByteArray()
	pba.resize(8)
	pba.encode_u64(0, p)
	
	var from = pba.decode_u16(0)
	var to = pba.decode_u16(2)
	var type = pba.decode_u8(4) & 0xF
	var coef = pba.decode_u32(4) >> 4
	
	if type == VirtualVertex.FIRST:
		return FirstVertex.new(from)
		
	elif type == VirtualVertex.INTERPOLATE:
		var real_coef = float(coef) / float((1 << 28) - 1)
		return InterpolateVertex.new(from, to, real_coef)

var symbol = null
var vertex_counter = -1
var virtual_vertices = []
var product_symbols = []
var product_vertices = []

var index = -1

func save():
	var vvs = []
	for vv in self.virtual_vertices:
		vvs.append(vv.pack())
	
	var prodsym = []
	for ps in self.product_symbols:
		prodsym.append(ps.text)
	
	return [vertex_counter, vvs, prodsym, product_vertices, index]
	
func l(data, symbol_map):
	self.vertex_counter = data[0]
	
	self.virtual_vertices = []
	for vv in data[1]:
		var uvv = unpack_vv(vv)
		self.virtual_vertices.append(uvv)
		
	self.product_symbols = []
	for ps in data[2]:
		self.product_symbols.append(symbol_map[ps])
		
	self.product_vertices = data[3]
	
func pack():
	return self.save()
	
static func from_packed(p, symbol, symbol_map):
	var gr = GrammarRule.new(p[4], symbol)
	gr.l(p, symbol_map)
	
	return gr

func serialize(symbol_id):
	var data = PackedByteArray()
	
	var verts_size = 0
	for verts in self.product_vertices:
		var s = verts.size()
		verts_size += s
		
	var buf_size = 4 + 8 * self.virtual_vertices.size() \
					+ 2 * self.product_vertices.size() \
					+ 2 * self.product_symbols.size() \
					+ 2 * verts_size
					
	# padding
	buf_size = snappedi(buf_size + 1.5, 4)
	
	data.resize(buf_size)
	
	# Sizes
	var i = 0
	data.encode_u16(i, self.virtual_vertices.size())
	i += 2
	data.encode_u8(i, self.product_symbols.size())
	i += 2
	
	# virtual vertices
	for vv in self.virtual_vertices:
		data.encode_u64(i, vv.pack())
		i += 8
		
	# product vertex sizes
	for verts in self.product_vertices:
		data.encode_u16(i, verts.size())
		i += 2
		
	# Product symbols
	for ps in self.product_symbols:
		data.encode_u16(i, symbol_id[ps])
		i += 2
	
	# Product vertives
	for verts in self.product_vertices:
		for vertex in verts:
			data.encode_u16(i, vertex)
			i += 2
			
	return data

func _init(_index, _symbol):
	self.index = _index
	
	self.symbol = _symbol
	self.vertex_counter = self.symbol.nr_of_vertices
	
	self.symbol.add_rule(_index, self)
	
func _add(vv):
	self.virtual_vertices.push_back(vv)
	var vv_index = self.vertex_counter
	self.vertex_counter += 1
	return vv_index

func add_copy_vertex(_index):
	var vv = FirstVertex.new(_index)
	return self._add(vv)
	
func add_interpolated_vertex(index1, index2, inter_coef):
	var vv = InterpolateVertex.new(index1, index2, inter_coef)
	return self._add(vv)
	
func add_product(_symbol, indices):
	self.product_symbols.push_back(_symbol)
	self.product_vertices.push_back(indices)

static func _select_vertices(va, indices):
	var selection = []
	for i in indices:
		selection.push_back(va[i])
		
	return selection

func fulfill(shape):
	var va = []
	va.append_array(shape.vertices)

	# Create virtual vertices
	for vv in self.virtual_vertices:
		var new_vertex = vv.create_vertex(va)
		va.push_back(new_vertex)

	# Create children
	var children = []
	for i in self.product_symbols.size():
		var sym = self.product_symbols[i]
		var indices = self.product_vertices[i]
		
		var selection = GrammarRule._select_vertices(va, indices)
		
		var new_shape = GrammarShape.new(sym, selection)
		children.push_back(new_shape)

	return children
