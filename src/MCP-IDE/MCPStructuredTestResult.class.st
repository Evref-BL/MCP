"
The result of one test case run by test_run, so that SUnit's own bookkeeping counts that test once, however many exceptions it raised.

It records each issue while the stack that raised it is still live: its kind, as SUnit sorts the exception, its error class and message, the first frame past the helpers that only pass an error on (the location), and, for a failure in the test method, the statement that failed. A location in Pharo's kernel or SUnit says where the error was noticed, so it also names the code under test that called it, at the line it was running. An issue raised again with the same kind, error class and message, as a broken fixture raises it in setUp and again in tearDown, adds its location to the first.

A class removed since is named by its own name, not by the one Pharo gives its obsolete copy, with the article before it to match, and the issue lists it among the classes it names that were removed. A name right after a quote or #, or after a quote and its article as in a quoted printString, is the text of a string or a symbol, and is left as it is.
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

{ #category : 'private - removed classes' }
MCPStructuredTestResult class >> article: anArticle agreeingWith: aName [
	"anArticle, a, an or nothing, followed by a space unless nothing, as aName takes it and capitalized as anArticle is."

	| article |
	anArticle ifEmpty: [ ^ anArticle ].
	article := aName first isVowel
		           ifTrue: [ 'an ' ]
		           ifFalse: [ 'a ' ].
	^ anArticle first isUppercase
		  ifTrue: [ article capitalized ]
		  ifFalse: [ article ]
]

{ #category : 'locations' }
MCPStructuredTestResult class >> codeUnderTestContextFrom: aLocationContext in: aTestCase [
	"When aLocationContext runs a method of Pharo's kernel or of SUnit, which says where the error was noticed rather than where it was made, the first context below it that runs neither theirs nor a helper's: the code under test, or the test itself. Nil otherwise, and when the walk reaches the test case's runCase first."

	| context packageNames |
	packageNames := self frameworkPackageNames.
	(self isContext: aLocationContext inAnyPackageOf: packageNames) ifFalse: [ ^ nil ].
	context := aLocationContext sender.
	[ context isNil or: [ self isRunCaseContext: context of: aTestCase ] ] whileFalse: [
			((self isHelperContext: context) or: [ self isContext: context inAnyPackageOf: packageNames ]) ifFalse: [ ^ context ].
			context := context sender ].
	^ nil
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> cutShort: aString [
	"aString, cut past 100 characters."

	^ aString size > 100
		  ifTrue: [ (aString first: 100) , '...' ]
		  ifFalse: [ aString ]
]

{ #category : 'private - locations' }
MCPStructuredTestResult class >> frameworkPackageNames [
	"The packages of Pharo's kernel, as its bootstrap baseline groups them, and SUnit's: what runs in them is never the code a test is testing."

	| names |
	names := Set with: TestCase package name asString.
	self environment
		at: #BaselineOfPharoBootstrap
		ifPresent: [ :baseline | baseline kernelPackageNames do: [ :each | names add: each asString ] ].
	^ names
]

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
MCPStructuredTestResult class >> isContext: aContext inAnyPackageOf: somePackageNames [
	"Whether the method aContext runs, or the one that defines the block it runs, belongs to one of somePackageNames."

	| package |
	package := (self homeMethodOf: aContext) ifNotNil: [ :method | method package ].
	^ package isNotNil and: [ somePackageNames includes: package name asString ]
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
MCPStructuredTestResult class >> issueLocationTextOf: aContext in: aTestCase [
	"Where an issue came from: aContext as Pharo prints it, and, when it runs Pharo's kernel or SUnit, the code under test that called it, at the line it was running: SmallInteger(Integer)>>>, called from ZooKeeper>>feed: at line 4: portion > appetite."

	^ String streamContents: [ :stream |
			  stream nextPutAll: (self locationTextOf: aContext).
			  (self codeUnderTestContextFrom: aContext in: aTestCase) ifNotNil: [ :caller |
					  stream
						  nextPutAll: ', called from ';
						  nextPutAll: (self locationTextOf: caller).
					  (self lineTextOf: caller) ifNotNil: [ :line |
							  stream
								  nextPutAll: ' at ';
								  nextPutAll: line ] ] ]
]

{ #category : 'locations' }
MCPStructuredTestResult class >> lineTextOf: aContext [
	"The line of its method that aContext was running, counting the method as stored, and that line, trimmed and cut past 100 characters: line 4: portion > appetite. Nil when it cannot be read."

	| node source |
	node := [ aContext sourceNodeExecuted ]
		        on: Error
		        do: [ :error | ^ nil ].
	node ifNil: [ ^ nil ].
	source := node methodNode source.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'line ';
				  print: (source lineNumberCorrespondingToIndex: node start);
				  nextPutAll: ': ';
				  nextPutAll: (self cutShort: (source lineCorrespondingToIndex: node start) trimBoth) ]
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
	"The receiver's class, the method's class in parentheses when it differs, and the selector: ZooLion class(ZooAnimal class)>>arrivedOn:. A clean block runs with no receiver, so the method's class alone names it."

	| method receiverClass |
	method := self homeMethodOf: aContext.
	receiverClass := aContext receiver class.
	^ String streamContents: [ :stream |
			  (receiverClass includesBehavior: method methodClass)
				  ifTrue: [
						  stream << receiverClass name.
						  method methodClass == receiverClass ifFalse: [ stream << '(' << method methodClass name << ')' ] ]
				  ifFalse: [ stream << method methodClass name ].
			  stream << '>>' << method selector ]
]

{ #category : 'private - removed classes' }
MCPStructuredTestResult class >> removedClassNamePattern [
	"A class Pharo removes is renamed AnObsolete followed by its name, once more each time it is removed again. The match takes the article before the name, which the class's own name may change, and the quote or # before either that makes them the text of a string or a symbol, as an instance's printString quoted reads 'an AnObsoleteZooLion'."

	^ '(''?\b[Aa]n? )?[''#]?\b(AnObsolete)+[A-Z][A-Za-z0-9_]*'
]

{ #category : 'locations' }
MCPStructuredTestResult class >> statementOf: aContext [
	"The statement directly in its method's body that aContext was running, on one line and cut past 100 characters, or nil when it cannot be read."

	| body methodNode node |
	node := [ aContext sourceNodeExecuted ]
		        on: Error
		        do: [ :error | ^ nil ].
	methodNode := (node ifNotNil: [ node methodNode ]) ifNil: [ ^ nil ].
	body := methodNode body.
	[ node parent isNil or: [ node parent == body ] ] whileFalse: [ node := node parent ].
	node parent == body ifFalse: [ ^ nil ].
	^ self cutShort: (' ' join: node sourceCode substrings)
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

{ #category : 'removed classes' }
MCPStructuredTestResult class >> textNamingRemovedClassesIn: aString into: someNames [
	"aString with each removed class named by its own name, not by the one Pharo gives it on removal, and with the article before it agreeing with that name: an AnObsoleteZooLion reads a ZooLion. Each such name goes into someNames once. A name in a string or a symbol, right after a quote or #, or after a quote and its article, is what the code compared or printed, and stays as it is."

	^ aString copyWithRegex: self removedClassNamePattern matchesTranslatedUsing: [ :match |
			  | article className index |
			  index := match indexOfSubCollection: 'AnObsolete'.
			  article := match first: index - 1.
			  ((article beginsWith: '''') or: [ (article endsWith: '''') or: [ article endsWith: '#' ] ])
				  ifTrue: [ match ]
				  ifFalse: [
						  className := match allButFirst: index - 1.
						  [ className beginsWith: 'AnObsolete' ] whileTrue: [ className := className allButFirst: 'AnObsolete' size ].
						  someNames addIfNotPresent: className.
						  (self article: article agreeingWith: className) , className ] ]
]

{ #category : 'private' }
MCPStructuredTestResult >> addIssueOfKind: aKind errorClass: anErrorClassName message: aMessage location: aLocationOrNil statement: aStatementOrNil [
	"An issue of the kind, error class and message of one the test already raised is the same issue, raised again somewhere else, such as in setUp and again in tearDown: its place joins the others once. A class removed since is named by its own name, and listed among the removed classes the issue names. Answer the issue."

	| issue location message removedClassNames |
	removedClassNames := OrderedCollection new.
	message := self class textNamingRemovedClassesIn: aMessage into: removedClassNames.
	location := aLocationOrNil ifNotNil: [ :text | self class textNamingRemovedClassesIn: text into: removedClassNames ].
	issue := issues
		         detect: [ :each |
		         (each at: #kind) = aKind and: [ (each at: #errorClass) = anErrorClassName and: [ (each at: #message) = message ] ] ]
		         ifNone: [
				         issues add: (Dictionary new
						          at: #kind put: aKind;
						          at: #errorClass put: anErrorClassName;
						          at: #message put: message;
						          at: #locations put: OrderedCollection new;
						          at: #removedClasses put: OrderedCollection new;
						          yourself) ].
	(location isNil or: [ (issue at: #locations) includes: location ]) ifFalse: [ (issue at: #locations) add: location ].
	removedClassNames do: [ :each | (issue at: #removedClasses) addIfNotPresent: each ].
	(aStatementOrNil isNil or: [ issue includesKey: #statement ]) ifFalse: [ issue at: #statement put: aStatementOrNil ].
	^ issue
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
	"Recorded while the stack that signalled is still live, so that the issue says where it came from: a place outside the test method, with the code under test that called it when that place is in Pharo's kernel or SUnit, or, for a failure in the test method, the statement that failed; and, for a message not understood, what it was most likely meant to be."

	| context issue kind location statement |
	kind := self issueKindOf: anException.
	context := self class locationContextFrom: anException signalerContext in: aTestCase.
	context ifNotNil: [
			(self class isTestMethodContext: context of: aTestCase)
				ifTrue: [ kind = 'failure' ifTrue: [ statement := self class statementOf: context ] ]
				ifFalse: [ location := self class issueLocationTextOf: context in: aTestCase ] ].
	issue := self
		         addIssueOfKind: kind
		         errorClass: anException class name
		         message: (self messageOf: anException forTestCase: aTestCase)
		         location: location
		         statement: statement.
	anException mcpTestIssueNote ifNotNil: [ :note | issue at: #note ifAbsentPut: [ note ] ]
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
