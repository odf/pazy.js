Array::equals ||= (other) ->
  if @length != other.length
    false
  else
    for i in [0...@length]
      return false unless equal this[i], other[i]
    true

Array::hashCode ||= ->
  val = 0
  val = val * 37 + hashCode(this[i]) for i in [0...@length]
  val

String::hashCode ||= ->
  unless @hashCode__?
    val = 0
    val = val * 37 + @charCodeAt(i) for i in [0...@length]
    @hashCode__ = val
  @hashCode__

equal = (obj1, obj2) ->
  if typeof(obj1?.equals) == 'function'
    obj1.equals obj2
  else if typeof(obj2?.equals) == 'function'
    obj2.equals obj1
  else
    obj1 == obj2

selfHashing = (obj) ->
  typeof(obj) == "number" and (0x100000000 > obj >= 0) and (obj % 1 == 0)

hashCode = (obj) ->
  if typeof(obj?.hashCode) == 'function'
    obj.hashCode()
  else if selfHashing obj
    obj
  else if typeof(obj.toString) == "function"
    hashCode obj.toString()
  else
    try
      hashCode String obj
    catch ex
      hashCode Object::toString.call obj

# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.equal = equal
exports.hashCode = hashCode
