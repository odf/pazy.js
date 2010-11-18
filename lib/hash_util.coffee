util = {
  hash : (obj) ->
    if typeof(obj.hashCode) == "function"
      code = obj.hashCode()
      if typeof(code) == "number" and code > 0 and code % 1 == 0
        return code

    stringVal =
      if typeof(obj) == "string"
        obj
      else if typeof(obj) == "object"
        ("#{k}:#{v}" for k,v of obj).join(",")
      else if typeof(obj.toString) == "function"
        obj.toString()
      else
        try
          String(obj)
        catch ex
          Object.prototype.toString.call(obj)

    _.reduce(stringVal, ((code, c) -> code * 37 + c.charCodeAt(0)), 0)

  equal: (obj1, obj2) ->
    if typeof(obj1.equals) == "function"
      obj1.equals(obj2)
    else if typeof(obj2.equals) == "function"
      obj2.equals(obj1)
    else
      obj1 == obj2


  arrayWith: (a, i, x) -> a[...i].concat([x], a[i+1..])

  arrayWithInsertion: (a, i, x) -> a[...i].concat([x], a[i..])

  arrayWithout: (a, i) -> a[...i].concat(a[i+1..])


  mask: (hash, shift) -> (hash >> shift) & 0x1f

  bitCount: (n) ->
    n -= (n >> 1) & 0x55555555
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    n = (n & 0x0f0f0f0f) + ((n >> 4) & 0x0f0f0f0f)
    n += n >> 8
    (n + (n >> 16)) & 0x3f

  indexForBit: (bitmap, bit) -> util.bitCount(bitmap & (bit - 1))

  bitPosAndIndex: (bitmap, hash, shift) ->
    bit = 1 << util.mask(hash, shift)
    [bit, util.indexForBit(bitmap, bit)]
}

# -- node.js exports:

this.hashUtil = util

if typeof(exports) != 'undefined'
  for key, val of util
    exports[key] = val
