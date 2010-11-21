this.suspend = (code) ->
  cache = {
    force: ->
      val = code()
      this.force = () -> val
      val
  }
  -> cache.force()

if typeof exports != 'undefined'
  exports.suspend = this.suspend
