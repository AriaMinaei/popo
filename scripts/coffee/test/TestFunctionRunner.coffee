require './_prepare'
wn = require 'when'

TestFunctionRunner = mod 'TestFunctionRunner'

describe "constructor()"

it "should accept a function", ->

	(-> new TestFunctionRunner ->).should.not.throw()

it "should not accept anything other than a function", ->

	(-> new TestFunctionRunner 'a').should.throw()

it "should accept functions with a done callback", ->

	(-> new TestFunctionRunner (done) ->).should.not.throw()

it "should not accept functions with more than one argument", ->

	(-> new TestFunctionRunner (first, second) ->).should.throw()

aSuccessfulRunner = ->

	new TestFunctionRunner ->

aFailingRunner = (error = "Some error message") ->

	new TestFunctionRunner -> throw Error error

describe "_isSinglePromise()"

it "should return yes for promises", ->

	TestFunctionRunner
	._isSinglePromise(wn.defer().promise).should.equal yes

it "should return no for non-promises", ->

	TestFunctionRunner
	._isSinglePromise([]).should.equal no

describe "_isPromise()"

it "should return yes for promises", ->

	TestFunctionRunner
	._isPromise(wn.defer().promise).should.equal yes

it "should return no for non-promises", ->

	TestFunctionRunner
	._isPromise([]).should.equal no

it "should return yes for arrays of promises", ->

	TestFunctionRunner
	._isPromise([wn.defer().promise]).should.equal yes

it "should return no for arrays of non-promises", ->

	TestFunctionRunner
	._isPromise([1, 2]).should.equal no

it "should throw for arrays of promises and non-promises", ->

	(-> TestFunctionRunner
	._isPromise([1, wn.defer().promise]).should.equal no
	).should.throw()

describe "_toPromise()"

it "should throw when supplied with a non-promise", ->

	(-> TestFunctionRunner._toPromise 1
	).should.throw()

it "should return original promise when supplied with a promise", ->

	promise = wn().then ->

	TestFunctionRunner._toPromise(promise).should.equal promise

it "should return promise when supplied with an array of promises", ->

	a = []
	a.push wn().then ->
	a.push wn().then ->
	a.push wn().then ->

	TestFunctionRunner._toPromise(a).should.have.property 'then'

describe "run()"

it "should always return a promise", ->

	aSuccessfulRunner().run()
	.should.satisfy(TestFunctionRunner._isSinglePromise).and.be.fulfilled

	aFailingRunner().run()
	.should.satisfy(TestFunctionRunner._isSinglePromise)
	.and.be.rejected

describe "run() - async"

it "should resolve when done is called with no args", ->

	r = new TestFunctionRunner (done) ->

		done()

	r.run().should.be.fulfilled

it "should reject when done is called with one arg", ->

	r = new TestFunctionRunner (done) ->

		done 'b'

	r.run().should.be.rejected

it "should reject when done is called with multiple args", ->

	r = new TestFunctionRunner (done) ->

		done 1, 2

	r.run().should.be.rejected

it "should reject when throws an error", ->

	r = new TestFunctionRunner (done) ->

		throw Error()

	r.run().should.be.rejected

it "should reject when throws an error, after done() is called", ->

	r = new TestFunctionRunner (done) ->

		done()

		throw Error()

	r.run().should.be.rejected

_it "should not allow multiple calls to done()", ->

	r = new TestFunctionRunner (done) ->

		done()

		done()

	(-> r.run()).should.throw()

it "should reject when returns a promise", ->

	r = new TestFunctionRunner (done) ->

		wn()

	r.run().should.be.rejected

it "should reject when returns a promise after done is called", ->

	r = new TestFunctionRunner (done) ->

		done()

		wn()

	r.run().should.be.rejected

describe "run() - sync"

it "should resolve when doesn't throw error", ->

	r = new TestFunctionRunner ->

		1.should.equal 1

	r.run().should.be.fulfilled

it "should reject when throws error", ->

	r = new TestFunctionRunner ->

		1.should.equal 2

	r.run().should.be.rejected

describe "run() - promise"

it "should resolve when doesn't throw error", ->

	r = new TestFunctionRunner ->

		wn().then ->

			1.should.equal 1

	r.run().should.be.fulfilled

it "should resolve when throws an error", ->

	r = new TestFunctionRunner ->

		wn().then ->

			1.should.equal 2

	r.run().should.be.rejected

it "should resolve when returns an array of fulfilled promises", ->

	r = new TestFunctionRunner ->

		a = []

		a.push wn().then -> 1.should.equal 1
		a.push wn().then -> 1.should.equal 1
		a.push wn().then -> 1.should.equal 1

		a

	r.run().should.be.fulfilled

it "should reject when returns an array of fulfilled and failed promises", ->

	r = new TestFunctionRunner ->

		a = []

		a.push wn().then -> 1.should.equal 1
		a.push wn().then -> 1.should.equal 2
		a.push wn().then -> 1.should.equal 1

		a

	r.run().should.be.rejected