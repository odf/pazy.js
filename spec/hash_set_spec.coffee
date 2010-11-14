require.paths.unshift './lib'

HashSet = require('hash_set').HashSet


describe "A Hash", ->

	describe "with two items the first of which is removed", ->
    hash = new HashSet().plus('A').plus('B').minus('A')

    it "should not be empty", ->
      expect(hash.isEmpty).toEqual false
