wn = require 'when'

module.exports = class TestFunctionRunner

	self = @

	constructor: (fn) ->

		unless typeof fn is 'function'

			throw Error "TestFunctionRunner should be supplied with a function"

		if fn.length > 1

			throw Error "supplied function must have either 0 arguments (for sync/promise) or 1 argument (for async)"

		@_fn = fn

		@_async = @_fn.length is 1

	run: (context = null) ->

		deferred = wn.defer()

		toReturn =

			hadError: no

			result: null

		ran = no

		if @_async

			cb =  ->

				unless ran

					args = arguments

					process.nextTick ->

						cb.apply @, args

					return

				if arguments.length is 1

					deferred.reject arguments[0]

				else if arguments.length > 1

					deferred.reject "done() must only be called with 0 arguments for success or 1 argument for failure. `#{arguments.length}` arguments given."

				else

					deferred.resolve()

				return

			try

				returned = @_fn.call context, cb

				ran = yes

				if self._isPromise returned

					deferred.reject "An asyncronous function is returning a promise"

			catch err

				ran = yes

				deferred.reject err

		else

			try

				returned = @_fn.call context

				ran = yes

				if self._isPromise returned

					wn(self._toPromise(returned)).then (result) ->

						deferred.resolve result

						return

					, (error) ->

						deferred.reject error

						return

				else

					deferred.resolve returned

			catch err

				ran = yes

				deferred.reject err



		return deferred.promise

	@_isSinglePromise: (val) ->

		return yes if val? and val.then?

		return no

	@_isArrayOfPromises: (val) ->

		return no unless Array.isArray val

		foundAPromise = no

		foundANonePromise = no

		for v in val

			if self._isSinglePromise v

				foundAPromise = yes

			else

				foundANonePromise = no

		if foundAPromise and foundANonePromise

			throw Error "The function has returned an array of promises and non-promises, so we can't determine if the array is meant to act as an array of promises or it's just an accidental return of an array"

		return yes if foundAPromise

		return no

	@_isPromise: (val) ->

		return yes if self._isSinglePromise val

		return self._isArrayOfPromises val

	@_toPromise: (val) ->

		if self._isSinglePromise val then return val

		if self._isArrayOfPromises val then return wn.all val

		throw Error "_toPromise() only accepts a promise or an array of promises"