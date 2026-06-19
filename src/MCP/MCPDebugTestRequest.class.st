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

	| stopAtName timeout |
	timeout := aRequest
		           nonNegativeIntegerArgumentNamed: 'timeoutMilliseconds'
		           default: self defaultTimeoutMilliseconds.
	timeout := timeout min: self maximumTimeoutMilliseconds.
	stopAtName := aRequest stringArgumentNamed: 'stopAt' default: 'test'.
	(self supportedStopPoints includes: stopAtName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugTestStopPointUnsupported
				message: 'Unsupported debug stopAt: ' , stopAtName asString , '.'
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
				   default: self defaultSourceContextLines
				   maximum: self maximumSourceContextLines);
		  stackStart: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackStart'
				   default: self defaultStackStart);
		  stackLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackLimit'
				   default: self defaultStackLimit
				   maximum: self maximumStackLimit);
		  variableDepth: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: self defaultVariableDepth
				   maximum: self maximumVariableDepth);
		  variableLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: self defaultVariableLimit
				   maximum: self maximumVariableLimit);
		  includeReceiver: (aRequest
				   booleanArgumentNamed: 'includeReceiver'
				   default: self defaultIncludeReceiver);
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
