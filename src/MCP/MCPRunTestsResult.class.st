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
		'coverage'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
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
MCPRunTestsResult >> compactIssueFor: issue [

	| data |
	data := Dictionary new.
	data at: #test put: (self testReferenceForIssue: issue).
	issue at: #message ifPresent: [ :message | message isEmpty ifFalse: [ data at: #message put: message ] ].
	(issue at: #kind ifAbsent: [ nil ]) = 'error' ifTrue: [
		issue at: #errorClass ifPresent: [ :className | data at: #errorClass put: className ] ].
	issue at: #parameters ifPresent: [ :parameters | parameters ifNotEmpty: [ data at: #parameters put: parameters ] ].
	^ data
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
MCPRunTestsResult >> errorDictionaries [

	^ Array streamContents: [ :stream | (self issuesOfKind: 'error') do: [ :issue | stream nextPut: (self compactIssueFor: issue) ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> failureDictionaries [

	^ Array streamContents: [ :stream |
		  (self issuesOfKind: 'failure') do: [ :issue | stream nextPut: (self compactIssueFor: issue) ] ]
]

{ #category : 'initialization' }
MCPRunTestsResult >> initializeResults: resultCollection timedOut: aBoolean unrunTests: testCollection [

	results := resultCollection asArray.
	timedOut := aBoolean.
	unrunTests := testCollection asArray.
	^ self
]

{ #category : 'converting' }
MCPRunTestsResult >> issuesOfKind: issueKind [

	^ Array streamContents: [ :stream |
			  self results do: [ :resultInfo |
				  resultInfo issues do: [ :issue | (issue at: #kind ifAbsent: [ nil ]) = issueKind ifTrue: [ stream nextPut: issue ] ] ] ]
]

{ #category : 'converting' }
MCPRunTestsResult >> passedCount [

	^ self results inject: 0 into: [ :sum :each | sum + each passedCount ]
]

{ #category : 'converting' }
MCPRunTestsResult >> resultDictionaries [

	^ (self results collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'accessing' }
MCPRunTestsResult >> results [

	^ results
]

{ #category : 'converting' }
MCPRunTestsResult >> runCount [

	^ self results inject: 0 into: [ :sum :each | sum + each runCount ]
]

{ #category : 'converting' }
MCPRunTestsResult >> skippedTestReferences [

	^ self uniqueStringsFrom: ((self issuesOfKind: 'skipped') collect: [ :issue | self testReferenceForIssue: issue ])
]

{ #category : 'converting' }
MCPRunTestsResult >> testReferenceForIssue: issue [

	^ (issue at: #className) asString , '>>#' , (issue at: #testMethodName) asString
]

{ #category : 'accessing' }
MCPRunTestsResult >> timedOut [

	^ timedOut
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

	^ (self unrunTests collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'accessing' }
MCPRunTestsResult >> unrunTests [

	^ unrunTests
]
