"
Request object for debug_test_run.

It identifies one SUnit test method and the test phase where debugger control should stop, plus timeout and returned debug_state_get shaping options.
"
Class {
	#name : 'MCPDebugTestRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'className',
		'testMethodName',
		'name',
		'timeoutMilliseconds',
		'resultPreviewCharacterLimit',
		'stopAt'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'defaults' }
MCPDebugTestRequest class >> defaultResultPreviewCharacterLimit [

	^ MCPDebugCaptureRequest defaultResultPreviewCharacterLimit
]

{ #category : 'defaults' }
MCPDebugTestRequest class >> defaultTimeoutMilliseconds [

	^ MCPDebugCaptureRequest defaultTimeoutMilliseconds
]

{ #category : 'instance creation' }
MCPDebugTestRequest class >> fromRequest: aRequest tool: aTool [

	| timeout stopAtName |
	timeout := aRequest
		           nonNegativeIntegerArgumentNamed: 'timeoutMilliseconds'
		           default: self defaultTimeoutMilliseconds.
	timeout := timeout min: self maximumTimeoutMilliseconds.
	stopAtName := aRequest stringArgumentNamed: 'stopAt' default: 'test'.
	(self supportedStopPoints includes: stopAtName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugTestStopPointUnsupported
				message:
				'Unsupported debug test stopAt: ' , stopAtName asString , '.'
				details: {
						(#stopAt -> stopAtName).
						(#supportedStopPoints -> self supportedStopPoints) }
						asDictionary ].
	^ self new
		  className: (aRequest stringArgumentNamed: 'className');
		  testMethodName: (aRequest stringArgumentNamed: 'testMethodName');
		  name:
			  (aRequest
				   stringArgumentNamed: 'name'
				   default: 'Debug test session');
		  timeoutMilliseconds: timeout;
		  resultPreviewCharacterLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'resultPreviewCharacterLimit'
				   default: self defaultResultPreviewCharacterLimit);
		  sourceContextLines: (aRequest
				   nonNegativeIntegerArgumentNamed: 'sourceContextLines'
				   default: 5);
		  stackStart:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackStart'
				   default: 0);
		  stackLimit:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackLimit'
				   default: 20);
		  variableDepth:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: 1);
		  variableLimit:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: 50);
		  includeReceiver:
			  (aRequest booleanArgumentNamed: 'includeReceiver' default: true);
		  stopAt: stopAtName;
		  yourself
]

{ #category : 'defaults' }
MCPDebugTestRequest class >> maximumTimeoutMilliseconds [

	^ MCPDebugCaptureRequest maximumTimeoutMilliseconds
]

{ #category : 'defaults' }
MCPDebugTestRequest class >> supportedStopPoints [

	^ #( 'test' 'setUp' 'tearDown' )
]

{ #category : 'accessing' }
MCPDebugTestRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPDebugTestRequest >> className: aString [

	className := aString
]

{ #category : 'accessing' }
MCPDebugTestRequest >> name [

	^ name
]

{ #category : 'accessing' }
MCPDebugTestRequest >> name: aString [

	name := aString
]

{ #category : 'accessing' }
MCPDebugTestRequest >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'accessing' }
MCPDebugTestRequest >> resultPreviewCharacterLimit: anInteger [

	resultPreviewCharacterLimit := anInteger
]

{ #category : 'accessing' }
MCPDebugTestRequest >> stopAt [

	^ stopAt
]

{ #category : 'accessing' }
MCPDebugTestRequest >> stopAt: aString [

	stopAt := aString
]

{ #category : 'accessing' }
MCPDebugTestRequest >> testMethodName [

	^ testMethodName
]

{ #category : 'accessing' }
MCPDebugTestRequest >> testMethodName: aString [

	testMethodName := aString
]

{ #category : 'accessing' }
MCPDebugTestRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds
]

{ #category : 'accessing' }
MCPDebugTestRequest >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger
]
