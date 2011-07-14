Array::equals ||= (other) ->
  if @length != other.length
    false
  else
    for i in [0...@length]
      return false unless equal this[i], other[i]
    true

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
  else
    s = "" + obj
    val = 0
    val = (val * 37 + s.charCodeAt(i)) & 0xffffffff for i in [0...s.length]
    val

# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.equal = equal
exports.hashCode = hashCode
