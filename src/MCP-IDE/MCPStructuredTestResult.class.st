"
The result of one test case run by test_run, so that SUnit's own bookkeeping counts that test once, however many exceptions it raised.

It records each issue while the stack that raised it is still live: its kind, as SUnit sorts the exception, its error class and message, the first frame past the helpers that only pass an error on (the location), and, for a failure in the test method, the statement that failed. An issue raised again with the same kind, error class and message, as a broken fixture raises it in setUp and again in tearDown, adds its location to the first.
"
Class {
	#name : 'MCPStructuredTestResult',
	#superclass : 'TestResult',
	#instVars : [
		'issues'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'private - locations' }
MCPStructuredTestResult class >> helperClasses [
	"Classes whose own methods only pass an error on or run a test, never the code that went wrong."

	^ {
		  ProtoObject.
		  Object.
		  Context.
		  Process.
		  TestAsserter.
		  TestCase.
		  self }
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> helperHierarchies [
	"Hierarchies whose methods, on either side, only signal, wait or evaluate."

	^ {
		  BlockClosure.
		  Delay.
		  Semaphore.
		  Exception }
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> homeMethodOf: aContext [
	"The method a context runs, or the one that defines the block it runs."

	^ aContext compiledCode method
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> isHelperContext: aContext [
	"A frame Pharo's debugger completes to its sender, or one of the kernel, SUnit or this result."

	| method methodClass |
	method := self homeMethodOf: aContext.
	method ifNil: [ ^ false ].
	(method hasPragmaNamed: #debuggerCompleteToSender) ifTrue: [ ^ true ].
	methodClass := method methodClass ifNil: [ ^ false ].
	(self helperClasses includes: methodClass) ifTrue: [ ^ true ].
	^ self helperHierarchies anySatisfy: [ :each | methodClass instanceSide includesBehavior: each ]
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> isRunCaseContext: aContext of: aTestCase [

	^ aContext receiver == aTestCase and: [ (self homeMethodOf: aContext) selector == #runCase ]
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> isTestMethodContext: aContext of: aTestCase [

	^ (self homeMethodOf: aContext) == (aTestCase class lookupSelector: aTestCase selector)
]

{ #category : 'locations' }
MCPStructuredTestResult class >> locationContextFrom: aContext in: aTestCase [
	"The first context from aContext toward the bottom of the stack that is not a helper, or nil when the walk reaches the test case's runCase first."

	| context |
	context := aContext.
	[ context isNil or: [ self isRunCaseContext: context of: aTestCase ] ] whileFalse: [
			(self isHelperContext: context) ifFalse: [ ^ context ].
			context := context sender ].
	^ nil
]

{ #category : 'locations' }
MCPStructuredTestResult class >> locationOf: aContext in: aTestCase [
	"Where code running in aContext was, as Pharo prints a context, or nil when that is the test method itself or no code of the test's own."

	^ (self locationContextFrom: aContext in: aTestCase) ifNotNil: [ :context |
		  (self isTestMethodContext: context of: aTestCase) ifFalse: [ self locationTextOf: context ] ]
]

{ #category : 'locations' }
MCPStructuredTestResult class >> locationTextOf: aContext [
	"The receiver's class, the method's class in parentheses when it differs, and the selector: ZooLion class(ZooAnimal class)>>arrivedOn:."

	| method receiverClass |
	method := self homeMethodOf: aContext.
	receiverClass := aContext receiver class.
	^ String streamContents: [ :stream |
			  stream << receiverClass name.
			  method methodClass == receiverClass ifFalse: [ stream << '(' << method methodClass name << ')' ].
			  stream << '>>' << method selector ]
]

{ #category : 'locations' }
MCPStructuredTestResult class >> statementOf: aContext [
	"The statement directly in its method's body that aContext was running, on one line and cut past 100 characters, or nil when it cannot be read."

	| body methodNode node text |
	node := [ aContext sourceNodeExecuted ]
		        on: Error
		        do: [ :error | ^ nil ].
	methodNode := (node ifNotNil: [ node methodNode ]) ifNil: [ ^ nil ].
	body := methodNode body.
	[ node parent isNil or: [ node parent == body ] ] whileFalse: [ node := node parent ].
	node parent == body ifFalse: [ ^ nil ].
	text := ' ' join: node sourceCode substrings.
	^ text size > 100
		  ifTrue: [ (text first: 100) , '...' ]
		  ifFalse: [ text ]
]

{ #category : 'printing' }
MCPStructuredTestResult class >> textForDuration: aDuration [
	"Whole seconds in seconds, anything else in milliseconds."

	| count milliseconds unit |
	milliseconds := aDuration asMilliSeconds.
	milliseconds \\ 1000 = 0
		ifTrue: [
				count := milliseconds // 1000.
				unit := 'second' ]
		ifFalse: [
				count := milliseconds.
				unit := 'millisecond' ].
	^ String streamContents: [ :stream |
			  stream
				  print: count;
				  space;
				  nextPutAll: unit.
			  count = 1 ifFalse: [ stream nextPut: $s ] ]
]

{ #category : 'private' }
MCPStructuredTestResult >> addIssueOfKind: aKind errorClass: anErrorClassName message: aMessage location: aLocationOrNil statement: aStatementOrNil [
	"An issue of the kind, error class and message of one the test already raised is the same issue, raised again somewhere else, such as in setUp and again in tearDown: its place joins the others once."

	| issue |
	issue := issues
		         detect: [ :each |
		         (each at: #kind) = aKind and: [ (each at: #errorClass) = anErrorClassName and: [ (each at: #message) = aMessage ] ] ]
		         ifNone: [
				         issues add: (Dictionary new
						          at: #kind put: aKind;
						          at: #errorClass put: anErrorClassName;
						          at: #message put: aMessage;
						          at: #locations put: OrderedCollection new;
						          yourself) ].
	(aLocationOrNil isNil or: [ (issue at: #locations) includes: aLocationOrNil ]) ifFalse: [
		(issue at: #locations) add: aLocationOrNil ].
	(aStatementOrNil isNil or: [ issue includesKey: #statement ]) ifFalse: [ issue at: #statement put: aStatementOrNil ]
]

{ #category : 'initialization' }
MCPStructuredTestResult >> initialize [

	super initialize.
	issues := OrderedCollection new
]

{ #category : 'private' }
MCPStructuredTestResult >> issueKindOf: anException [
	"As SUnit sorts what it caught: a skip, a failure or a warning, or else an error. The test's own membership would label an assertion failing in tearDown after a setUp error an error."

	(self class skip handles: anException) ifTrue: [ ^ 'skipped' ].
	((self class failure handles: anException) or: [ self class warning handles: anException ]) ifTrue: [ ^ 'failure' ].
	^ 'error'
]

{ #category : 'accessing' }
MCPStructuredTestResult >> issues [
	"The issues the test raised, one per kind, error class and message, in the order they were first raised."

	^ issues asArray
]

{ #category : 'private' }
MCPStructuredTestResult >> messageOf: anException forTestCase: aTestCase [
	"A time limit SUnit enforced has no message of its own, so it says which limit it was."

	| timeLimit |
	((TestTookTooMuchTime handles: anException) and: [ anException messageText isEmpty ]) ifTrue: [
			timeLimit := self timeLimitOf: aTestCase.
			timeLimit ifNotNil: [ ^ 'took longer than its time limit of ' , (self class textForDuration: timeLimit) ] ].
	^ anException messageText ifNil: [ '' ] ifNotNil: [ :text | text asString ]
]

{ #category : 'private' }
MCPStructuredTestResult >> recordIssueFrom: anException forTestCase: aTestCase [
	"Recorded while the stack that signalled is still live, so that the issue says where it came from: a place outside the test method, or, for a failure in the test method, the statement that failed."

	| context kind location statement |
	kind := self issueKindOf: anException.
	context := self class locationContextFrom: anException signalerContext in: aTestCase.
	context ifNotNil: [
			(self class isTestMethodContext: context of: aTestCase)
				ifTrue: [ kind = 'failure' ifTrue: [ statement := self class statementOf: context ] ]
				ifFalse: [ location := self class locationTextOf: context ] ].
	self
		addIssueOfKind: kind
		errorClass: anException class name
		message: (self messageOf: anException forTestCase: aTestCase)
		location: location
		statement: statement
]

{ #category : 'running' }
MCPStructuredTestResult >> runCase: aTestCase [
	"The issue is recorded before SUnit counts it, while the stack that signalled is live, since counting may pass it on."

	[
		aTestCase announce: TestCaseStarted withResult: self.
		aTestCase runCaseManaged.
		aTestCase announce: TestCaseEnded withResult: self.
		self addPass: aTestCase ]
		on: self class failure , self class skip , self class warning , self class error
		do: [ :ex |
				self recordIssueFrom: ex forTestCase: aTestCase.
				ex sunitAnnounce: aTestCase toResult: self ]
]

{ #category : 'private' }
MCPStructuredTestResult >> timeLimitOf: aTestCase [
	"The limit SUnit is enforcing on the test now, or nil when it cannot be read."

	^ [
		  | environment |
		  environment := aTestCase executionEnvironment.
		  environment isTest
			  ifTrue: [ environment maxTimeForTest ]
			  ifFalse: [ aTestCase defaultTimeLimit ] ]
		  on: Error
		  do: [ :error | nil ]
]
