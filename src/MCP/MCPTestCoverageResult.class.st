"
Structured coverage result DTO returned by test_coverage_run.
"
Class {
	#name : 'MCPTestCoverageResult',
	#superclass : 'Object',
	#instVars : [
		'coverageResult',
		'includeCoveredMethods',
		'methodLimit',
		'partiallyCoveredMethods'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPTestCoverageResult class >> coverageResult: aCoverageResult includeCoveredMethods: aBoolean methodLimit: anInteger partiallyCoveredMethods: partialMethods [

	^ self new
		  initializeCoverageResult: aCoverageResult
		  includeCoveredMethods: aBoolean
		  methodLimit: anInteger
		  partiallyCoveredMethods: partialMethods
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> allMethods [

	^ self coverageResult collector methods asArray
]

{ #category : 'converting' }
MCPTestCoverageResult >> asDictionary [

	| coveredMethods data fullyCoveredMethods partialMethods uncoveredMethods |
	coveredMethods := self coveredMethods.
	fullyCoveredMethods := self fullyCoveredMethods.
	uncoveredMethods := self uncoveredMethods.
	partialMethods := self partiallyCoveredMethods.
	data := Dictionary new.
	data at: #methodCount put: self allMethods size.
	data at: #coveredMethodCount put: coveredMethods size.
	data at: #fullyCoveredMethodCount put: fullyCoveredMethods size.
	data at: #uncoveredMethodCount put: uncoveredMethods size.
	data at: #partiallyCoveredMethodCount put: partialMethods size.
	data at: #nodeCount put: self nodeCount.
	data at: #coveredNodeCount put: self coveredNodeCount.
	data at: #percentage put: self percentage.
	data
		at: #uncoveredMethods
		put: (self methodDictionariesFor: uncoveredMethods).
	data
		at: #partiallyCoveredMethods
		put: (self methodDictionariesFor: partialMethods).
	data
		at: #uncoveredMethodsTruncated
		put: (self isListTruncated: uncoveredMethods).
	data
		at: #partiallyCoveredMethodsTruncated
		put: (self isListTruncated: partialMethods).
	self includeCoveredMethods ifTrue: [
		data
			at: #coveredMethods
			put: (self methodDictionariesFor: coveredMethods).
		data
			at: #coveredMethodsTruncated
			put: (self isListTruncated: coveredMethods) ].
	^ data
]

{ #category : 'accessing' }
MCPTestCoverageResult >> coverageResult [

	^ coverageResult
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> coveredMethods [

	^ self coverageResult methods asArray
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> coveredNodeCount [

	^ self coverageResult nodes size
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> fullyCoveredMethods [

	| partialMethods |
	partialMethods := self partiallyCoveredMethods.
	^ self coveredMethods reject: [ :method |
		  partialMethods includes: method ]
]

{ #category : 'accessing' }
MCPTestCoverageResult >> includeCoveredMethods [

	^ includeCoveredMethods = true
]

{ #category : 'initialization' }
MCPTestCoverageResult >> initializeCoverageResult: aCoverageResult includeCoveredMethods: aBoolean methodLimit: anInteger partiallyCoveredMethods: partialMethods [

	coverageResult := aCoverageResult.
	includeCoveredMethods := aBoolean = true.
	methodLimit := anInteger.
	partiallyCoveredMethods := partialMethods ifNil: [ #(  ) ]
]

{ #category : 'private - methods' }
MCPTestCoverageResult >> isListTruncated: methods [

	^ self methodLimit < methods size
]

{ #category : 'private - methods' }
MCPTestCoverageResult >> methodDictionariesFor: methods [

	| limited sorted |
	sorted := self sortedMethods: methods.
	limited := self methodLimit = 0
		           ifTrue: [ #(  ) ]
		           ifFalse: [
		           sorted first: (self methodLimit min: sorted size) ].
	^ (limited collect: [ :each | self methodDictionaryFor: each ])
		  asArray
]

{ #category : 'private - methods' }
MCPTestCoverageResult >> methodDictionaryFor: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromMethod: aCompiledMethod)
		  asDictionaryIncludingSource: false
]

{ #category : 'accessing' }
MCPTestCoverageResult >> methodLimit [

	^ methodLimit ifNil: [ 50 ]
]

{ #category : 'private - methods' }
MCPTestCoverageResult >> methodSortKeyFor: aCompiledMethod [

	^ String streamContents: [ :stream |
		  stream nextPutAll: aCompiledMethod methodClass instanceSide name.
		  aCompiledMethod methodClass isMeta ifTrue: [
			  stream nextPutAll: ' class' ].
		  stream
			  nextPutAll: '>>';
			  nextPutAll: aCompiledMethod selector asString ]
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> nodeCount [

	^ self coverageResult collector nodes size
]

{ #category : 'accessing' }
MCPTestCoverageResult >> partiallyCoveredMethods [

	^ partiallyCoveredMethods ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestCoverageResult >> percentage [

	| percentage |
	percentage := self coverageResult percentage.
	percentage isNaN ifTrue: [ ^ nil ].
	^ percentage asFloat
]

{ #category : 'private - methods' }
MCPTestCoverageResult >> sortedMethods: methods [

	^ methods asSortedCollection: [ :left :right |
		  (self methodSortKeyFor: left) <= (self methodSortKeyFor: right) ]
]

{ #category : 'private - coverage' }
MCPTestCoverageResult >> uncoveredMethods [

	^ self coverageResult uncoveredMethods asArray
]
