require '../_prepare'

TestCase = mod 'testTree/TestCase'

failedCase = ->

	new TestCase null, fn: ->

		wn().then -> throw Error "This should fail"

successfulCase = ->

	new TestCase null, fn: ->

		wn().then -> 1.should.equal 1

describe "constructor()"

it "should work", ->

	t = new TestCase null, fn: ->