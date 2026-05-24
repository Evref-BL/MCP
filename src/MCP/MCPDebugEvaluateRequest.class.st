Class {
	#name : 'MCPDebugEvaluateRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'expression',
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugEvaluateRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  operation: 'evaluate';
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  expression: (aRequest stringArgumentNamed: 'expression');
		  resultPreviewCharacterLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'resultPreviewCharacterLimit'
				   default: aTool resultPreviewCharacterLimit);
		  yourself
]

{ #category : 'accessing' }
MCPDebugEvaluateRequest >> expression [

	^ expression
]

{ #category : 'accessing' }
MCPDebugEvaluateRequest >> expression: aString [

	expression := aString
]

{ #category : 'accessing' }
MCPDebugEvaluateRequest >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit ifNil: [ 10000 ]
]

{ #category : 'accessing' }
MCPDebugEvaluateRequest >> resultPreviewCharacterLimit: anInteger [

	resultPreviewCharacterLimit := anInteger
]
