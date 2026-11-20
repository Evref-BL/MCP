"
Run test packages, classes, or methods and return compact aggregate results.
"
Class {
	#name : 'MCPToolRunTests',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRunTests class >> groupName [

	^ self testsGroupName
]

{ #category : 'metadata' }
MCPToolRunTests class >> toolName [

	^ 'test_run'
]

{ #category : 'private - arguments' }
MCPToolRunTests >> addMethodSelectionsFrom: methodReferences to: aStream [
	"A method is read in every form method_get reads one, and its side is dropped: test_run reads Foo class as Foo. A case of a parameterized test is read as its method, so the name an answer gives it can be passed back. Every entry that names no method is refused, all in one refusal."

	| violations |
	violations := OrderedCollection new.
	methodReferences do: [ :each |
			(MCPMethodReference fromString: each)
				ifNil: [ violations add: (self violationForMethodReference: each) ]
				ifNotNil: [ :reference |
					aStream nextPut:
						(MCPTestSelectionSpec className: reference className testMethodName: (self testSelectorIn: reference selector)) ] ].
	violations ifNotEmpty: [ MCPInvalidToolInput signalForTool: self violations: violations ]
]

{ #category : 'metadata' }
MCPToolRunTests >> additionalKeywords [

	^ #( 'test' 'sunit' 'timeout' )
]

{ #category : 'metadata' }
MCPToolRunTests >> buildInputSchema [

	^ MCPStructureInputSchema properties: self testSelectionInputProperties , { self timeoutSecondsProperty } required: #(  )
]

{ #category : 'private - arguments' }
MCPToolRunTests >> checkArguments: request [
	"What the schema cannot check: that the call names something to run, and that every method reference names a method."

	self testSelectionsFrom: request
]

{ #category : 'private' }
MCPToolRunTests >> classesDefinedAgainSentenceFor: someEntries [
	"<classes> exist(s) again, but <methods> still refer(s) to its|their removed copy|copies: compile that method|those methods again with method_compile, unchanged, and it|they will refer to the current <classes>. A references search finds only the current classes' references, so the methods are named, each once."

	| classNames methods |
	classNames := someEntries collect: [ :each | self valueIn: each at: #class ].
	methods := OrderedCollection new.
	someEntries do: [ :each | (self valueIn: each at: #methods) do: [ :method | methods addIfNotPresent: method ] ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (MCPCommandError joinedNames: classNames);
				  nextPutAll: (classNames size = 1
						   ifTrue: [ ' exists again, but ' ]
						   ifFalse: [ ' exist again, but ' ]);
				  nextPutAll: (MCPCommandError joinedNames: methods);
				  nextPutAll: (methods size = 1
						   ifTrue: [ ' still refers to ' ]
						   ifFalse: [ ' still refer to ' ]);
				  nextPutAll: (classNames size = 1
						   ifTrue: [ 'its removed copy' ]
						   ifFalse: [ 'their removed copies' ]);
				  nextPutAll: (methods size = 1
						   ifTrue: [ ': compile that method' ]
						   ifFalse: [ ': compile those methods' ]);
				  nextPutAll: ' again with method_compile, unchanged, and ';
				  nextPutAll: (methods size = 1
						   ifTrue: [ 'it' ]
						   ifFalse: [ 'they' ]);
				  nextPutAll: ' will refer to the current ';
				  nextPutAll: (MCPCommandError joinedNames: classNames);
				  nextPut: $. ]
]

{ #category : 'private - results' }
MCPToolRunTests >> dataTextOn: stream for: data [
	"Each issue is read as a line naming the tests it hit, why and where, failures first, then errors, then skips; what a timeout left to run follows as a record."

	| rest |
	#( #failures 'failed' #errors 'error' #skipped 'skipped' ) pairsDo: [ :key :label |
		(self valueIn: data at: key) ifNotNil: [ :entries |
			entries do: [ :entry | self issueLineOn: stream for: entry labelled: label ] ] ].
	rest := data copy.
	#( failures errors skipped ) do: [ :key |
			rest removeKey: key ifAbsent: [ nil ].
			rest removeKey: key asString ifAbsent: [ nil ] ].
	super dataTextOn: stream for: rest
]

{ #category : 'metadata' }
MCPToolRunTests >> defaultExposure [

	^ 'static'
]

{ #category : 'defaults' }
MCPToolRunTests >> defaultTimeoutSeconds [

	^ 90
]

{ #category : 'metadata' }
MCPToolRunTests >> description [

	^ 'Run SUnit tests by package, class or Class>>selector, and report failures and errors.'
]

{ #category : 'executing' }
MCPToolRunTests >> executeWithRequest: request [
	"The arguments are checked, then the selections they name run. An error raised before the arguments are checked names the tests as the caller wrote them."

	| checked |
	checked := false.
	^ self
		  executeRequest: request
		  do: [
				  self checkArguments: request.
				  checked := true.
				  self runTestsWith: request ]
		  onError: [ :error |
				  | testNames |
				  testNames := self testNamesFor: request checked: checked.
				  self
					  errorResultFor: error
					  unableTo: (testNames ifEmpty: [ 'run tests' ] ifNotEmpty: [ 'run tests: ' , (', ' join: testNames) ])
					  details: #(  ) ]
]

{ #category : 'private' }
MCPToolRunTests >> issueCountsOn: stream for: data [
	"1 failure, 1 error. A count of none is left out, and so is the sentence when both are."

	| parts |
	parts := OrderedCollection new.
	#( #failureCount 'failure' #errorCount 'error' ) pairsDo: [ :key :noun |
		(self valueIn: data at: key) ifNotNil: [ :count | count isZero ifFalse: [ parts add: (self textForCount: count noun: noun) ] ] ].
	parts ifEmpty: [ ^ self ].
	stream
		space;
		nextPutAll: (', ' join: parts);
		nextPut: $.
]

{ #category : 'private - results' }
MCPToolRunTests >> issueLineOn: stream for: entry labelled: aLabel [
	"failed <who>[: <message>][, at <statement> | , in <locations>][; <classes> was|were removed]; error <who> (<ErrorClass>)[: <message>][, in <locations>][; <classes> was|were removed][. <note>]; skipped <who>[: <reason>]. A message loses one trailing period when something follows it."

	| locations message note removedClasses statement |
	stream
		nextPut: Character lf;
		nextPutAll: aLabel;
		space;
		nextPutAll: (', ' join: ((self valueIn: entry at: #tests) ifNil: [ #(  ) ])).
	(self valueIn: entry at: #errorClass) ifNotNil: [ :errorClass | stream << ' (' << errorClass << ')' ].
	statement := self valueIn: entry at: #statement.
	locations := (self valueIn: entry at: #locations) ifNil: [ #(  ) ].
	note := self valueIn: entry at: #note.
	removedClasses := (self valueIn: entry at: #removedClasses) ifNil: [ #(  ) ].
	message := (self valueIn: entry at: #message) ifNil: [ self valueIn: entry at: #reason ].
	message ifNotNil: [
			stream
				nextPutAll: ': ';
				nextPutAll: ((statement isNil and: [ locations isEmpty and: [ removedClasses isEmpty and: [ note isNil ] ] ])
						 ifTrue: [ message ]
						 ifFalse: [ self textWithoutFinalPeriod: message ]) ].
	statement ifNotNil: [ stream << ', at ' << statement ].
	locations ifNotEmpty: [ stream << ', in ' << (MCPCommandError joinedNames: locations) ].
	removedClasses ifNotEmpty: [
			stream
				nextPutAll: '; ';
				nextPutAll: (MCPCommandError joinedNames: removedClasses);
				nextPutAll: (removedClasses size = 1
						 ifTrue: [ ' was removed' ]
						 ifFalse: [ ' were removed' ]) ].
	note ifNotNil: [ stream << '. ' << note ]
]

{ #category : 'private - results' }
MCPToolRunTests >> keysStatedInSummary [
	"The summary already says the counts, the tests that refer to removed classes, the selections that held no test and the timeout: 'Ran 2 tests (0 passed). 2 errors. Timed out after 90 seconds, during T>>#testC. 7 tests not run, listed below as test_run arguments.'"

	^ #( runCount passedCount failureCount errorCount skippedCount removedClassReferences classesDefinedAgain withoutTests
	     timedOut timeoutMilliseconds interrupted notRunCount )
]

{ #category : 'private - execution' }
MCPToolRunTests >> operationFor: request [
	"The run the checked arguments ask for."

	^ MCPRunTestsCommand selections: (self testSelectionsFrom: request) timeoutMilliseconds: (self timeoutMillisecondsFrom: request)
]

{ #category : 'private - errors' }
MCPToolRunTests >> rawStringCollectionNamed: argumentName fromRequest: rawRequest [

	| value |
	value := rawRequest argumentNamed: argumentName ifAbsent: [ ^ #(  ) ].
	value isArray ifFalse: [ ^ #(  ) ].
	^ value collect: [ :each | each asString ] as: Array
]

{ #category : 'private - errors' }
MCPToolRunTests >> rawTestNamesFromRequest: rawRequest [

	^ Array streamContents: [ :stream |
			  #( 'packages' 'classes' 'methods' ) do: [ :argumentName |
				  (self rawStringCollectionNamed: argumentName fromRequest: rawRequest) do: [ :each | stream nextPut: each ] ] ]
]

{ #category : 'private - arguments' }
MCPToolRunTests >> refuseEmptySelectionIn: request [
	"An argument that names nothing once blank values are dropped is named, the first of packages, classes and methods. With none given at all, the call names nothing to run."

	#( 'packages' 'classes' 'methods' ) do: [ :argumentName |
			(request argumentNamed: argumentName ifAbsent: [ nil ]) ifNotNil: [
				MCPInvalidToolInput signalEmptyArgumentNamed: argumentName forTool: self ] ].
	MCPInvalidToolInput signalForTool: self violations: { (MCPJSONSchemaViolation
			 path: #(  )
			 keyword: #selectionRequired
			 message: 'Name at least one package, class or method to run.'
			 expected: nil
			 actual: nil) }
]

{ #category : 'private' }
MCPToolRunTests >> removedClassReferenceSentenceFor: entry [
	"<tests> refers to <class>, a removed class, so it ran the obsolete copy of <class>. <tests> refer to <classes>, removed classes, so they ran the obsolete copies of those classes."

	| classes tests |
	classes := self valueIn: entry at: #classes.
	tests := self valueIn: entry at: #tests.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (MCPCommandError joinedNames: tests);
				  nextPutAll: (tests size = 1
						   ifTrue: [ ' refers to ' ]
						   ifFalse: [ ' refer to ' ]);
				  nextPutAll: (MCPCommandError joinedNames: classes);
				  nextPutAll: (classes size = 1
						   ifTrue: [ ', a removed class, so ' ]
						   ifFalse: [ ', removed classes, so ' ]);
				  nextPutAll: (tests size = 1
						   ifTrue: [ 'it' ]
						   ifFalse: [ 'they' ]);
				  nextPutAll: (classes size = 1
						   ifTrue: [ ' ran the obsolete copy of ' , classes first ]
						   ifFalse: [ ' ran the obsolete copies of those classes' ]);
				  nextPut: $. ]
]

{ #category : 'private' }
MCPToolRunTests >> removedClassReferencesSentencesOn: stream for: data [
	"One sentence per set of removed classes that tests refer to, then: Create <the classes nothing has the name of> again with class_create, or change the test(s). Then one sentence for the classes that exist again, naming each method that still refers to a removed copy once."

	| classesDefinedAgain missingClassNames namesDefinedAgain sentences testCount |
	classesDefinedAgain := (self valueIn: data at: #classesDefinedAgain) ifNil: [ #(  ) ].
	namesDefinedAgain := classesDefinedAgain collect: [ :each | self valueIn: each at: #class ].
	missingClassNames := OrderedCollection new.
	testCount := 0.
	sentences := OrderedCollection new.
	(self valueIn: data at: #removedClassReferences) do: [ :entry |
			sentences add: (self removedClassReferenceSentenceFor: entry).
			((self valueIn: entry at: #classes) reject: [ :each | namesDefinedAgain includes: each ]) ifNotEmpty: [ :missing |
					missing do: [ :each | missingClassNames addIfNotPresent: each ].
					testCount := testCount + (self valueIn: entry at: #tests) size ] ].
	missingClassNames ifNotEmpty: [
			sentences add: (String streamContents: [ :sentence |
						 sentence
							 nextPutAll: 'Create ';
							 nextPutAll: (MCPCommandError joinedNames: missingClassNames);
							 nextPutAll: ' again with class_create, or change the ';
							 nextPutAll: (testCount = 1
									  ifTrue: [ 'test.' ]
									  ifFalse: [ 'tests.' ]) ]) ].
	classesDefinedAgain ifNotEmpty: [ sentences add: (self classesDefinedAgainSentenceFor: classesDefinedAgain) ].
	stream nextPutAll: (' ' join: sentences)
]

{ #category : 'private - execution' }
MCPToolRunTests >> runTestsWith: request [
	"Runs the selections the checked arguments name, and says what they did."

	| data operation |
	operation := self operationFor: request.
	data := operation execute asDictionary.
	^ self successResultText: (self successSummaryForData: data) data: data warnings: (self warningsFor: operation)
]

{ #category : 'private' }
MCPToolRunTests >> successSummaryForData: data [
	"Ran <N test(s)> (<P> passed).[ <F failure(s)>, <E error(s)>.][ <S> skipped.][ <removed class sentences>][ <selection sentences>][ <timeout sentence>] The opening stays on every answer that runs, a timeout's included, since graders read it."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Ran ';
				  nextPutAll: (self textForCount: (self valueIn: data at: #runCount) noun: 'test');
				  nextPutAll: ' (';
				  print: (self valueIn: data at: #passedCount);
				  nextPutAll: ' passed).'.
			  self issueCountsOn: stream for: data.
			  (self valueIn: data at: #skippedCount) ifNotNil: [ :count |
					  stream
						  space;
						  print: count;
						  nextPutAll: ' skipped.' ].
			  (self valueIn: data at: #removedClassReferences) ifNotNil: [
					  stream space.
					  self removedClassReferencesSentencesOn: stream for: data ].
			  ((self valueIn: data at: #withoutTests) ifNil: [ #(  ) ]) do: [ :entry |
					  stream space.
					  self withoutTestsSentenceOn: stream for: entry ].
			  (self valueIn: data at: #timedOut) = true ifTrue: [
					  stream space.
					  self timeoutSentenceOn: stream for: data ] ]
]

{ #category : 'private - errors' }
MCPToolRunTests >> testNamesFor: request checked: aBoolean [
	"The tests an error names: as the selections read them once the arguments are checked, else as the caller wrote them."

	aBoolean ifTrue: [ ^ (self testSelectionsFrom: request) collect: [ :each | each displayName ] as: Array ].
	^ self rawTestNamesFromRequest: request
]

{ #category : 'private - tests' }
MCPToolRunTests >> testSelectionInputProperties [

	^ {
		  (self stringArraySchemaNamed: 'packages' description: 'Run every test class in these packages.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'classes' description: 'Run these test classes.' itemDescription: nil).
		  (self stringArraySchemaNamed: 'methods' description: 'Run these test methods, as Class>>selector.' itemDescription: nil) }
]

{ #category : 'private - arguments' }
MCPToolRunTests >> testSelectionsFrom: request [
	"Every selection, in the order packages, classes, methods. The refusals answer like the schema's."

	| classNames methodReferences packageNames |
	packageNames := request uniqueStringCollectionArgumentNamed: 'packages'.
	classNames := request uniqueStringCollectionArgumentNamed: 'classes'.
	methodReferences := request uniqueStringCollectionArgumentNamed: 'methods'.
	(packageNames isEmpty and: [ classNames isEmpty and: [ methodReferences isEmpty ] ]) ifTrue: [
		self refuseEmptySelectionIn: request ].
	^ Array streamContents: [ :stream |
			  packageNames do: [ :each | stream nextPut: (MCPTestSelectionSpec packageName: each) ].
			  classNames do: [ :each | stream nextPut: (MCPTestSelectionSpec className: each) ].
			  self addMethodSelectionsFrom: methodReferences to: stream ]
]

{ #category : 'private - arguments' }
MCPToolRunTests >> testSelectorIn: aSelectorText [
	"The selector of a test as an answer names it. A case of a parameterized test is named Class>>#selector with its parameters, and a test selector is unary, so what follows the selector's first ' with ' is the case's parameters, and passing that name back runs every case of the method."

	| index |
	index := aSelectorText indexOfSubCollection: ' with '.
	index isZero ifTrue: [ ^ aSelectorText ].
	^ (aSelectorText first: index - 1) trimBoth
]

{ #category : 'private - arguments' }
MCPToolRunTests >> timeoutMillisecondsFrom: request [

	^ (request integerArgumentOrDefaultNamed: 'timeoutSeconds') * 1000
]

{ #category : 'private - schema' }
MCPToolRunTests >> timeoutSecondsProperty [

	| property |
	property := self
		            integerSchemaPropertyNamed: 'timeoutSeconds'
		            description: 'Give up after this many seconds and report what ran by then. 0 answers at once.'
		            default: self defaultTimeoutSeconds.
	property minimum: 0.
	^ property
]

{ #category : 'private' }
MCPToolRunTests >> timeoutSentenceOn: stream for: data [
	"Timed out after <duration>[, during <test>[, in <location>]]. <M test(s)> not run, listed below as test_run arguments. A timeout of 0 runs nothing, and says so."

	| milliseconds notRun |
	milliseconds := self valueIn: data at: #timeoutMilliseconds.
	notRun := String streamContents: [ :notRunStream |
			          notRunStream
				          nextPutAll: (self textForCount: ((self valueIn: data at: #notRunCount) ifNil: [ 0 ]) noun: 'test');
				          nextPutAll: ' not run, listed below as ';
				          nextPutAll: self name;
				          nextPutAll: ' arguments.' ].
	milliseconds = 0 ifTrue: [
			stream
				nextPutAll: 'timeoutSeconds is 0, so nothing ran; ';
				nextPutAll: notRun.
			^ self ].
	stream nextPutAll: 'Timed out'.
	milliseconds ifNotNil: [
			stream
				nextPutAll: ' after ';
				nextPutAll: (MCPStructuredTestResult textForDuration: (Duration milliSeconds: milliseconds)) ].
	(self valueIn: data at: #interrupted) ifNotNil: [ :interrupted |
			stream
				nextPutAll: ', during ';
				nextPutAll: (self valueIn: interrupted at: #test).
			(self valueIn: interrupted at: #location) ifNotNil: [ :location |
					stream
						nextPutAll: ', in ';
						nextPutAll: location ] ].
	stream
		nextPutAll: '. ';
		nextPutAll: notRun
]

{ #category : 'metadata' }
MCPToolRunTests >> title [

	^ 'Run Tests'
]

{ #category : 'private - arguments' }
MCPToolRunTests >> violationForMethodReference: aString [

	^ MCPJSONSchemaViolation
		  path: #( 'methods' )
		  keyword: #methodReference
		  message: aString , ' is not a method reference; write it as Class>>#selector.'
		  expected: nil
		  actual: aString
]

{ #category : 'private - results' }
MCPToolRunTests >> warningsFor: anOperation [
	"test_run refuses a selection that names nothing before anything runs, so a call that ran has nothing to warn of."

	^ #(  )
]

{ #category : 'private' }
MCPToolRunTests >> withoutTestsSentenceOn: stream for: entry [
	"ZooKeeperTest has no tests."

	stream
		nextPutAll: (self valueIn: entry at: #selection);
		space;
		nextPutAll: (self valueIn: entry at: #reason);
		nextPut: $.
]
