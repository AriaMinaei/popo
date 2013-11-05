wn = require 'when'

###*
 * TestFunctionRunner
 * @type Function
 *
 * Runs what goes inside an "it" function, and takes care of the
 * async/promise parts.
 *
 * Examples:
 *
 * - 	r = new TestFunctionRunner -> 1.should.equal 1
 * 	r.run().then -> // will return a fulfilled promise
 *
 * - 	r = new TestFunctionRunner -> 1.should.equal 2
 * 	r.run() // will return a failed promise, with the error being the reason
 *
 * - 	r = new TestFunctionRunner (done) -> setTimeout done, 100
 * 	r.run() // will fulfill
 *
 * - 	r = new TestFunctionRunner (done) -> setTimeout (-> done "error"), 100
 * 	r.run() // will fail, with "error" being the reason
 *
 * - 	r = new TestFunctionRunner -> somePromise.then -> 1.should.equal 1
 * 	r.run() // will fulfill
 *
 * - 	r = new TestFunctionRunner -> somePromise.then -> 1.should.equal 2
 * 	r.run() // will fail
 *
 * - 	r = new TestFunctionRunner -> [promise1, promise2]
 * 	r.run() // will fulfill if both promises fulfill
 *
###
module.exports = class TestFunctionRunner

	self = @

	# Accepts a function
	constructor: (fn) ->

		unless typeof fn is 'function'

			throw Error "TestFunctionRunner should be supplied with a function"

		if fn.length > 1

			throw Error "supplied function must have either 0 arguments (for sync/promise) or 1 argument (for async)"

		@_fn = fn

		# If fn accepts a "done" argument, we'll run it async
		@_async = @_fn.length is 1

	# Runs the function in the given context, returns a promise
	run: (context = null) ->

		deferred = wn.defer()

		# Let's remember if we ran the function
		ran = no

		if @_async

			theDoneCallback = ->

				# postpone the callback if the function hasn't completed yet
				unless ran

					args = arguments

					process.nextTick ->

						theDoneCallback.apply @, args

					return

				if arguments.length is 1

					deferred.reject arguments[0]

				else if arguments.length > 1

					deferred.reject "done() must only be called with 0 arguments for success or 1 argument for failure. `#{arguments.length}` arguments given."

				else

					deferred.resolve()

				return

			try

				returned = @_fn.call context, theDoneCallback

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

	# Is val a promise
	@_isSinglePromise: (val) ->

		return yes if val? and val.then?

		return no

	# Is val an array of promises
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

	# is val a single promise of an array of promises
	@_isPromise: (val) ->

		return yes if self._isSinglePromise val

		return self._isArrayOfPromises val

	# turns single promise or array of promises into a promise
	@_toPromise: (val) ->

		if self._isSinglePromise val then return val

		if self._isArrayOfPromises val then return wn.all val

		throw Error "_toPromise() only accepts a promise or an array of promises"