suspend = (code) ->
  cache = {
    force: ->
      val = code()
      this.force = () -> val
      val
  }
  -> cache.force()

if typeof exports == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.suspend = suspend
else
  exports.suspend = suspend
