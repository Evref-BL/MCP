"
Request object for debug-capture.

It carries the expression to run in a worker process, the session name to use if an exception is captured, timeout settings, and result preview limits.
"
Class {
	#name : 'MCPDebugCaptureRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'expression',
		'name',
		'timeoutMilliseconds',
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'defaults' }
MCPDebugCaptureRequest class >> defaultResultPreviewCharacterLimit [

	^ 10000
]

{ #category : 'defaults' }
MCPDebugCaptureRequest class >> defaultTimeoutMilliseconds [

	^ 5000
]

{ #category : 'instance creation' }
MCPDebugCaptureRequest class >> fromRequest: aRequest tool: aTool [

	| timeout |
	timeout := aRequest
		           nonNegativeIntegerArgumentNamed: 'timeoutMilliseconds'
		           default: self defaultTimeoutMilliseconds.
	timeout := timeout min: self maximumTimeoutMilliseconds.
	^ self new
		  expression: (aRequest stringArgumentNamed: 'expression');
		  name: (aRequest
				   stringArgumentNamed: 'name'
				   default: 'Captured debug session');
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
MCPDebugCaptureRequest class >> maximumTimeoutMilliseconds [

	^ 30000
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> expression [

	^ expression
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> expression: aString [

	expression := aString
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> name [

	^ name ifNil: [ 'Captured debug session' ]
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> name: aString [

	name := aString
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit ifNil: [
		  self class defaultResultPreviewCharacterLimit ]
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> resultPreviewCharacterLimit: anInteger [

	resultPreviewCharacterLimit := anInteger
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> timeoutMilliseconds [

	^ timeoutMilliseconds ifNil: [ self class defaultTimeoutMilliseconds ]
]

{ #category : 'accessing' }
MCPDebugCaptureRequest >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger
]
