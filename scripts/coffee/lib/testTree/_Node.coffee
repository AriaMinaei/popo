module.exports = class _Node

	constructor: (@_parent, @_options = {}) ->

		@_prepared = no

		@_skipped = Boolean @_options.skipped

		@_init.apply @, arguments

	_shouldBeCountedAsPending: ->

		not @_skipped

	_init: ->

	prepare: ->

		if @_prepared

			throw Error "This node is already prepared"

		@_prepared = yes

		do @_prepare