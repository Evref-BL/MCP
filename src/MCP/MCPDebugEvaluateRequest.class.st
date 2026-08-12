"
Request object for frame-scoped debugger evaluation.

It carries the expression to evaluate and the preview limit used when rendering the result or error details.
"
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
		  operation: 'image_evaluate';
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  expression: (aRequest stringArgumentNamed: 'expression');
		  resultPreviewCharacterLimit:
			  (aRequest nonNegativeIntegerArgumentNamed: 'resultPreviewCharacterLimit' default: aTool resultPreviewCharacterLimit);
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
