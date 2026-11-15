"
Aggregate result DTO produced by test_run and test_coverage_run.

It counts each test once, from the outcomes of the selections it ran. It says each issue once: the issues of the same kind, error class, message and places, across tests, are one entry naming every test they hit, and a class whose whole suite ran and failed alike is named as Class, all N tests. It also carries the selections that selected no test, what a timeout left to run as test_run arguments, and coverage when it was measured.
"
Class {
	#name : 'MCPRunTestsResult',
	#superclass : 'MCPResult',
	#instVars : [
		'results',
		'timedOut',
		'unrunTests',
		'coverage',
		'interruption',
		'notRunCount',
		'timeoutMilliseconds',
		'withoutTests',
		'suiteSizes'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRunTestsResult class >> results: resultCollection timedOut: aBoolean unrunTests: testCollection [

	^ self new initializeResults: resultCollection timedOut: aBoolean unrunTests: testCollection
]

{ #category : 'converting' }
MCPRunTestsResult >> addTimeoutTo: data [
	"A timeout is reported only when it left tests unrun: the call's timeout, the test it interrupted, how many tests were not run and the test_run arguments that run them."

	data at: #timedOut put: true.
	self timeoutMilliseconds ifNotNil: [ :milliseconds | data at: #timeoutMilliseconds put: milliseconds ].
	self interruption ifNotNil: [ :outcome | data at: #interrupted put: (self interruptedDictionaryFor: outcome) ].
	data at: #notRunCount put: self notRunCount.
	data at: #notRun put: self notRunDictionary
]

{ #category : 'converting' }
MCPRunTestsResult >> asDictionary [
	"The counts, each test counted once and a count of none left out but for the run and the passes; each issue once, naming every test it hit; the selections that held no test; what a timeout left to run; and coverage."

	| data |
	data := Dictionary new.
	data at: #runCount put: self runCount.
	data at: #passedCount put: self passedCount.
	{
		(#failureCount -> self failureCount).
		(#errorCount -> self errorCount).
		(#skippedCount -> self skippedCount) } do: [ :each | each value isZero ifFalse: [ data at: each key put: each value ] ].
	{
		(#failures -> self failureDictionaries).
		(#errors -> self errorDictionaries).
		(#skipped -> self skippedDictionaries).
		(#withoutTests -> self withoutTests) } do: [ :each | each value ifNotEmpty: [ data at: each key put: each value ] ].
	self coverage ifNotNil: [ :coverageResult | data at: #coverage put: coverageResult asDictionary ].
	self timedOut ifTrue: [ self addTimeoutTo: data ].
	^ data
]

{ #category : 'converting' }
MCPRunTestsResult >> countOf: aSelector [

	^ self results inject: 0 into: [ :sum :each | sum + (each perform: aSelector) ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> coverage [

	^ coverage
]

{ #category : 'accessing' }
MCPRunTestsResult >> coverage: aCoverageResult [

	coverage := aCoverageResult
]

{ #category : 'converting' }
MCPRunTestsResult >> entryForIssueGroup: someTestIssues [
	"The tests an issue hit, each once, and what it says. A statement is said only for a group of one test, so that tests failing the same way still group. Empty fields are left out."

	| data issue |
	issue := someTestIssues first value.
	data := Dictionary new.
	data at: #tests put: (self testNamesOf: (someTestIssues collect: [ :each | each key ])).
	(issue at: #kind) = 'skipped' ifTrue: [
			(issue at: #message) ifNotEmpty: [ :reason | data at: #reason put: reason ].
			^ data ].
	(issue at: #kind) = 'error' ifTrue: [ data at: #errorClass put: (issue at: #errorClass) asString ].
	(issue at: #message) ifNotEmpty: [ :message | data at: #message put: message ].
	(issue at: #locations) ifNotEmpty: [ :locations | data at: #locations put: locations asArray ].
	someTestIssues size = 1 ifTrue: [ issue at: #statement ifPresent: [ :statement | data at: #statement put: statement ] ].
	^ data
]

{ #category : 'converting' }
MCPRunTestsResult >> errorCount [

	^ self countOf: #errorCount
]

{ #category : 'converting' }
MCPRunTestsResult >> errorDictionaries [

	^ self issueEntriesOfKind: 'error'
]

{ #category : 'converting' }
MCPRunTestsResult >> failureCount [

	^ self countOf: #failureCount
]

{ #category : 'converting' }
MCPRunTestsResult >> failureDictionaries [

	^ self issueEntriesOfKind: 'failure'
]

{ #category : 'initialization' }
MCPRunTestsResult >> initializeResults: resultCollection timedOut: aBoolean unrunTests: testCollection [

	results := resultCollection asArray.
	timedOut := aBoolean.
	unrunTests := testCollection asArray.
	^ self
]

{ #category : 'converting' }
MCPRunTestsResult >> interruptedDictionaryFor: anOutcome [
	"The test a timeout interrupted, and where it was unless that was the test method."

	| entry |
	entry := Dictionary new.
	entry at: #test put: anOutcome name.
	anOutcome location ifNotNil: [ :location | entry at: #location put: location ].
	^ entry
]

{ #category : 'accessing' }
MCPRunTestsResult >> interruption [
	"The test the timeout interrupted, as an outcome that says where it was, or nil when the deadline fell between tests."

	^ interruption
]

{ #category : 'accessing' }
MCPRunTestsResult >> interruption: anOutcomeOrNil [

	interruption := anOutcomeOrNil
]

{ #category : 'converting' }
MCPRunTestsResult >> issueEntriesOfKind: aKind [
	"One entry per issue of aKind, said once for every test it hit, in the order the first of those tests ran."

	^ (self issueGroupsOfKind: aKind) collect: [ :each | self entryForIssueGroup: each ] as: Array
]

{ #category : 'converting' }
MCPRunTestsResult >> issueGroupsOfKind: aKind [
	"The issues of aKind, as groups of test -> issue: issues with the same error class, message and places, across tests, are one group. A skip's line says no place, so skips are grouped by their reason alone. An unexpected pass raised nothing, so its issue has no error class."

	| groups |
	groups := OrderedCollection new.
	self outcomes do: [ :outcome |
			(outcome issuesOfKind: aKind) do: [ :issue |
					| key |
					key := {
						       (issue at: #errorClass ifAbsent: [ '' ]) asString.
						       (issue at: #message).
						       (aKind = 'skipped'
							        ifTrue: [ #(  ) ]
							        ifFalse: [ (issue at: #locations) asArray ]) }.
					(groups detect: [ :each | each key = key ] ifNone: [ groups add: key -> OrderedCollection new ]) value add: outcome -> issue ] ].
	^ groups collect: [ :each | each value asArray ] as: Array
]

{ #category : 'accessing' }
MCPRunTestsResult >> notRunCount [
	"How many tests a timeout left unrun: the interrupted one, the rest of its selection and the later selections' tests no earlier one ran."

	^ notRunCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> notRunCount: anInteger [

	notRunCount := anInteger
]

{ #category : 'converting' }
MCPRunTestsResult >> notRunDictionary [
	"What a timeout left to run, as test_run arguments."

	| notRun |
	notRun := Dictionary new.
	{
		(#packages -> self unrunPackageNames).
		(#classes -> self unrunClassNames).
		(#methods -> self unrunMethodReferences) } do: [ :each | each value ifNotEmpty: [ notRun at: each key put: each value ] ].
	^ notRun
]

{ #category : 'accessing' }
MCPRunTestsResult >> outcomes [
	"Every test that finished, each once, in the order they ran."

	^ Array streamContents: [ :stream | self results do: [ :each | stream nextPutAll: each outcomes ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> passedCount [

	^ self countOf: #passedCount
]

{ #category : 'accessing' }
MCPRunTestsResult >> results [

	^ results
]

{ #category : 'converting' }
MCPRunTestsResult >> runCount [

	^ self countOf: #runCount
]

{ #category : 'converting' }
MCPRunTestsResult >> skippedCount [

	^ self countOf: #skippedCount
]

{ #category : 'converting' }
MCPRunTestsResult >> skippedDictionaries [

	^ self issueEntriesOfKind: 'skipped'
]

{ #category : 'accessing' }
MCPRunTestsResult >> suiteSizeOf: aClassName [
	"How many cases the class's own suite holds, for a class that ran."

	^ self suiteSizes at: aClassName ifAbsent: [ 0 ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> suiteSizes [
	"The number of cases each class that ran holds in its own suite, by class name."

	^ suiteSizes ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> suiteSizes: aDictionary [

	suiteSizes := aDictionary
]

{ #category : 'converting' }
MCPRunTestsResult >> testNamesOf: someOutcomes [
	"The tests' names, each once, in the order they ran. A class all of whose outcomes are here, whose whole suite ran in this call, and that has more than one test, is named once, where its first test was: Class, all N tests."

	| said wholeSuites |
	wholeSuites := self wholeSuiteClassNamesIn: someOutcomes.
	said := Set new.
	^ Array streamContents: [ :stream |
			  someOutcomes do: [ :each |
					  | name |
					  name := (wholeSuites includes: each className)
						          ifTrue: [ self wholeSuiteNameOf: each className ]
						          ifFalse: [ each name ].
					  (said includes: name) ifFalse: [
							  said add: name.
							  stream nextPut: name ] ] ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> timedOut [

	^ timedOut
]

{ #category : 'accessing' }
MCPRunTestsResult >> timeoutMilliseconds [
	"The call's timeout, once it has fallen."

	^ timeoutMilliseconds
]

{ #category : 'accessing' }
MCPRunTestsResult >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger
]

{ #category : 'converting' }
MCPRunTestsResult >> uniqueStringsFrom: strings [

	| seen |
	seen := Set new.
	^ Array streamContents: [ :stream |
			  strings do: [ :each |
					  (seen includes: each) ifFalse: [
							  seen add: each.
							  stream nextPut: each ] ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> unrunClassNames [

	^ self uniqueStringsFrom: (Array streamContents: [ :stream |
				   self unrunTests do: [ :request |
					   (request isPackageRequest not and: [ request hasTestMethod not ]) ifTrue: [ stream nextPut: request className ] ] ])
]

{ #category : 'converting' }
MCPRunTestsResult >> unrunMethodReferences [

	^ self uniqueStringsFrom: (Array streamContents: [ :stream |
			   self unrunTests do: [ :request | request hasTestMethod ifTrue: [ stream nextPut: request displayName ] ] ])
]

{ #category : 'converting' }
MCPRunTestsResult >> unrunPackageNames [

	^ self uniqueStringsFrom: (Array streamContents: [ :stream |
			   self unrunTests do: [ :request | request isPackageRequest ifTrue: [ stream nextPut: request packageName ] ] ])
]

{ #category : 'accessing' }
MCPRunTestsResult >> unrunTests [

	^ unrunTests
]

{ #category : 'converting' }
MCPRunTestsResult >> wholeSuiteClassNamesIn: someOutcomes [
	"The classes that someOutcomes hold every outcome of, whose whole suite ran in this call, and that have more than one test."

	| inGroup inRun |
	inGroup := Bag withAll: (someOutcomes collect: [ :each | each className ]).
	inRun := Bag withAll: (self outcomes collect: [ :each | each className ]).
	^ inGroup asSet select: [ :each |
			  | size |
			  size := self suiteSizeOf: each.
			  size > 1 and: [ (inGroup occurrencesOf: each) = size and: [ (inRun occurrencesOf: each) = size ] ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> wholeSuiteNameOf: aClassName [
	"Class, all N tests."

	^ String streamContents: [ :stream |
			  stream << aClassName << ', all '.
			  stream print: (self suiteSizeOf: aClassName).
			  stream << ' tests' ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> withoutTests [
	"One entry per selection that selected no test, in selection order: its selection, why, and the packages of the test classes that refer to it when the call selected no test at all."

	^ withoutTests ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRunTestsResult >> withoutTests: someEntries [

	withoutTests := someEntries
]
