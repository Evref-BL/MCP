"
Parsed request for the shared test runner command. It contains parsed test requests, the timeout converted to milliseconds, and the internal operation selected by the concrete tool. Coverage requests are supplied by MCPToolRunTestCoverage.
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

{ #category : 'instance creation' }
MCPRunTestsRequest class >> fromRequest: aRequest tool: aTool operation: operation [

	| coverageRequest |
	(#( 'run' 'coverage' ) includes: operation) ifFalse: [
		Error signal: 'operation must be one of run or coverage.' ].
	coverageRequest := operation = 'coverage' ifTrue: [
			                   MCPTestCoverageRequest
				                   fromValue:
				                   (aRequest
					                    argumentNamed: 'coverage'
					                    ifAbsent: [ nil ])
				                   usingToolRequest: aRequest
				                   defaultMethodLimit:
				                   aTool defaultCoverageMethodLimit ].
	^ self new
		  initializeTestRequests:
		  (self testRequestsFromToolRequest: aRequest)
		  timeoutMilliseconds: (self
				   timeoutMillisecondsFromToolRequest: aRequest
				   defaultSeconds: aTool defaultTimeoutSeconds)
		  operation: operation
		  coverageRequest: coverageRequest
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> testRequestsFromToolRequest: request [

	| requests |
	requests := request objectCollectionArgumentNamed: 'tests'.
	requests ifEmpty: [
		Error signal: 'tests must contain at least one test request.' ].
	^ (requests collect: [ :each |
		   MCPTestRunRequest fromValue: each usingToolRequest: request ])
		  asArray
]

{ #category : 'private - parsing' }
MCPRunTestsRequest class >> timeoutMillisecondsFromToolRequest: request defaultSeconds: defaultSeconds [

	((request hasArgumentNamed: 'timeoutSeconds') and: [
		 request hasArgumentNamed: 'timeoutMilliseconds' ]) ifTrue: [
			Error signal:
				'timeoutSeconds and timeoutMilliseconds cannot both be provided.' ].
	(request hasArgumentNamed: 'timeoutMilliseconds') ifTrue: [
			^ request
				  nonNegativeIntegerArgumentNamed: 'timeoutMilliseconds'
				  default: defaultSeconds * 1000 ].
	^ (request
		   nonNegativeIntegerArgumentNamed: 'timeoutSeconds'
		   default: defaultSeconds) * 1000
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
	coverageRequest := aCoverageRequest
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
