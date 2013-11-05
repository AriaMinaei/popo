_Node = require './_Node'

module.exports = class Branch extends _Node

	_init: ->

		@_children = []

		@_pending = 0

	addChild: (child) ->

		unless child isntanceof _Node

			throw Error "addChild() only accepts instances of _Node"

		@_children.push child

		@_pending++

		@

	_prepare: ->

		for child in @_children

			child.prepare()

		return

	run: ->

