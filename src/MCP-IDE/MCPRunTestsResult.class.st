"
Aggregate result DTO produced by test_run.

It exposes compact public output: aggregate counts, compact failure/error details, skipped test references, timeout leftovers, and optional coverage.
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
		'timeoutMilliseconds'
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
MCPRunTestsResult >> asDictionary [

	| data errors failures skipped unrunClasses unrunMethods unrunPackages |
	data := Dictionary new.
	data at: #runCount put: self runCount.
	data at: #passedCount put: self passedCount.
	skipped := self skippedTestReferences.
	skipped ifNotEmpty: [ data at: #skipped put: skipped ].
	failures := self failureDictionaries.
	failures ifNotEmpty: [ data at: #failures put: failures ].
	errors := self errorDictionaries.
	errors ifNotEmpty: [ data at: #errors put: errors ].
	self coverage ifNotNil: [ :coverageResult | data at: #coverage put: coverageResult asDictionary ].
	self timedOut ifTrue: [
			data at: #timedOut put: true.
			unrunPackages := self unrunPackageNames.
			unrunPackages ifNotEmpty: [ data at: #unrunPackages put: unrunPackages ].
			unrunClasses := self unrunClassNames.
			unrunClasses ifNotEmpty: [ data at: #unrunClasses put: unrunClasses ].
			unrunMethods := self unrunMethodReferences.
			unrunMethods ifNotEmpty: [ data at: #unrunMethods put: unrunMethods ] ].
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
MCPRunTestsResult >> entryForIssue: issue of: anOutcome [

	| data |
	data := Dictionary new.
	data at: #test put: anOutcome reference.
	(issue at: #message) ifNotEmpty: [ :message | data at: #message put: message ].
	(issue at: #kind) = 'error' ifTrue: [ data at: #errorClass put: (issue at: #errorClass) ].
	anOutcome parameters ifNotEmpty: [ :parameters | data at: #parameters put: parameters ].
	(issue at: #locations) ifNotEmpty: [ :locations | data at: #locations put: locations asArray ].
	issue at: #statement ifPresent: [ :statement | data at: #statement put: statement ].
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
	"One entry per issue of aKind each test raised, in the order the tests ran."

	^ Array streamContents: [ :stream |
			  self outcomes do: [ :outcome |
				  (outcome issuesOfKind: aKind) do: [ :issue | stream nextPut: (self entryForIssue: issue of: outcome) ] ] ]
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

{ #category : 'accessing' }
MCPRunTestsResult >> outcomes [
	"Every test that finished, each once, in the order they ran."

	^ Array streamContents: [ :stream | self results do: [ :each | stream nextPutAll: each outcomes ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> passedCount [

	^ self countOf: #passedCount
]

{ #category : 'converting' }
MCPRunTestsResult >> resultDictionaries [

	^ self results collect: [ :each | each asDictionary ] as: Array
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
MCPRunTestsResult >> skippedTestReferences [

	^ self uniqueStringsFrom:
		  (self outcomes select: [ :each | (each issuesOfKind: 'skipped') isNotEmpty ] thenCollect: [ :each | each reference ])
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

{ #category : 'converting' }
MCPRunTestsResult >> unrunTestDictionaries [

	^ self unrunTests collect: [ :each | each asDictionary ] as: Array
]

{ #category : 'accessing' }
MCPRunTestsResult >> unrunTests [

	^ unrunTests
]
