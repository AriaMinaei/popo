_Node = require './_Node'
TestFunctionRunner = require '../TestFunctionRunner'

module.exports = class TestCase extends _Node

	_init: ->

		@_fn = new TestFunctionRunner @_options.fn