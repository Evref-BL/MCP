"
Parsed run-tests tool request derived from one validated MCPToolRequest.

It contains parsed MCPTestRunRequest entries and the timeout converted to milliseconds.
"
Class {
	#name : 'MCPRunTestsRequest',
	#superclass : 'Object',
	#instVars : [
		'testRequests',
		'timeoutMilliseconds'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRunTestsRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  initializeTestRequests:
		  (self testRequestsFromToolRequest: aRequest)
		  timeoutMilliseconds: (self
				   timeoutMillisecondsFromToolRequest: aRequest
				   defaultSeconds: aTool defaultTimeoutSeconds)
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

	^ (request
		   nonNegativeIntegerArgumentNamed: 'timeoutSeconds'
		   default: defaultSeconds) * 1000
]

{ #category : 'initialization' }
MCPRunTestsRequest >> initializeTestRequests: aCollection timeoutMilliseconds: anInteger [

	testRequests := aCollection.
	timeoutMilliseconds := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPRunTestsRequest >> testRequests [

	^ testRequests
]

{ #category : 'accessing' }
MCPRunTestsRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds
]
