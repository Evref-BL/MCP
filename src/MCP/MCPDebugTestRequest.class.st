"
Request object for debug-test.

It identifies one SUnit test method to run under debugger capture, plus the timeout and returned debug-state shaping options.
"
Class {
	#name : 'MCPDebugTestRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'className',
		'testMethodName',
		'name',
		'timeoutMilliseconds',
		'resultPreviewCharacterLimit'
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

	| timeout |
	timeout := aRequest
		           nonNegativeIntegerArgumentNamed: 'timeoutMilliseconds'
		           default: self defaultTimeoutMilliseconds.
	timeout := timeout min: self maximumTimeoutMilliseconds.
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
		  yourself
]

{ #category : 'defaults' }
MCPDebugTestRequest class >> maximumTimeoutMilliseconds [

	^ MCPDebugCaptureRequest maximumTimeoutMilliseconds
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
