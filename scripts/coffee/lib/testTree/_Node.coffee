module.exports = class _Node

	constructor: (@_parent, options = {}) ->

		@_prepared = no

		@_skipped = Boolean options.skipped

		@_init.apply @, arguments

	_shouldBeCountedAsPending: ->

		not @_skipped

	_init: ->

	prepare: ->

		if @_prepared

			throw Error "This node is already prepared"

		@_prepared = yes

		do @_prepare