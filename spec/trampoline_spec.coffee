if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  pazy = require('trampoline')

recur = pazy.recur
resolve = pazy.resolve


describe "A function computing the factorial via simulated tail recursion", ->
  factorial = (n) ->
    fac = (n, p) -> if n then recur -> fac(n-1, p * n) else p
    resolve fac(n, 1)

  it "should print 5040 when applied to 7", ->
    expect(factorial(7)).toBe 5040
