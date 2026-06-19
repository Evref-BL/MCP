"
Request object for debug_capture.

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
