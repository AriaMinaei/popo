Branch = require './testTree/Branch'

module.exports = class TestTree

	constructor: ->

		@_rootNode = new Branch null