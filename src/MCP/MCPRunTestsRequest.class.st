"
Parsed request shared by test_run and test_coverage_run.

It stores compact test selections, timeout converted to milliseconds, and the internal operation selected by the concrete tool. Coverage requests are supplied by MCPToolRunTestCoverage.
"
Class {
	#name : 'MCPRunTestsRequest',
	#superclass : 'Object',
	#instVars : [
		'testRequests',
		'timeoutMilliseconds',
		'operation',
		'coverageRequest'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addClassNames: classNames to: requests [

	classNames do: [ :className | requests add: (MCPTestRunRequest className: className) ]
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addMethodReferences: methodReferences to: requests [

	methodReferences do: [ :methodReference | requests add: (MCPTestRunRequest fromMethodReference: methodReference) ]
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> addPackageNames: packageNames to: requests [

	packageNames do: [ :packageName | requests add: (MCPTestRunRequest packageName: packageName) ]
]

{ #category : 'instance creation' }
MCPRunTestsRequest class >> fromRequest: aRequest tool: aTool operation: operation [

	| coverageRequest |
	(#( 'run' 'coverage' ) includes: operation) ifFalse: [ Error signal: 'operation must be run or coverage.' ].
	coverageRequest := operation = 'coverage' ifTrue: [
			                   MCPTestCoverageRequest
				                   fromValue: (aRequest argumentNamed: 'coverage' ifAbsent: [ nil ])
				                   usingToolRequest: aRequest
				                   defaultMethodLimit: aTool defaultCoverageMethodLimit ].
	^ self new
		  initializeTestRequests: (self testRequestsFromToolRequest: aRequest)
		  timeoutMilliseconds: (self timeoutMillisecondsFromToolRequest: aRequest defaultSeconds: aTool defaultTimeoutSeconds)
		  operation: operation
		  coverageRequest: coverageRequest
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> testRequestsFromToolRequest: request [

	| classNames methodReferences packageNames requests |
	packageNames := request uniqueStringCollectionArgumentNamed: 'packages' default: #(  ).
	classNames := request uniqueStringCollectionArgumentNamed: 'classes' default: #(  ).
	methodReferences := request uniqueStringCollectionArgumentNamed: 'methods' default: #(  ).
	(packageNames isEmpty and: [ classNames isEmpty and: [ methodReferences isEmpty ] ]) ifTrue: [
		Error signal: 'Provide at least one package, class, or method.' ].
	requests := OrderedCollection new.
	self addPackageNames: packageNames to: requests.
	self addClassNames: classNames to: requests.
	self addMethodReferences: methodReferences to: requests.
	requests ifEmpty: [ Error signal: 'No test classes or methods matched request.' ].
	^ requests asArray
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> timeoutMillisecondsFromToolRequest: request defaultSeconds: defaultSeconds [

	^ (request nonNegativeIntegerArgumentNamed: 'timeoutSeconds' default: defaultSeconds) * 1000
]

{ #category : 'accessing' }
MCPRunTestsRequest >> coverageRequest [

	^ coverageRequest
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger [

	^ self
		  initializeTestRequests: aCollection
		  timeoutMilliseconds: anInteger
		  operation: 'run'
		  coverageRequest: nil
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger operation: operationString coverageRequest: aCoverageRequest [

	testRequests := aCollection.
	timeoutMilliseconds := anInteger.
	operation := operationString ifNil: [ 'run' ].
	coverageRequest := aCoverageRequest.
	^ self
]

{ #category : 'testing' }
MCPRunTestsRequest >> isCoverageOperation [

	^ self operation = 'coverage'
]

{ #category : 'accessing' }
MCPRunTestsRequest >> operation [

	^ operation ifNil: [ 'run' ]
]

{ #category : 'accessing' }
MCPRunTestsRequest >> testRequests [

	^ testRequests
]

{ #category : 'accessing' }
MCPRunTestsRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds
]
