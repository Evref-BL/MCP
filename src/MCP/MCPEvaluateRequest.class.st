"
Parsed evaluate tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPEvaluateRequest',
	#superclass : 'Object',
	#instVars : [
		'code',
		'frame'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPEvaluateRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  frame: (aRequest stringArgumentNamed: 'frame');
		  initializeCode: (aRequest stringArgumentNamed: 'code')
]

{ #category : 'accessing' }
MCPEvaluateRequest >> code [

	^ code
]

{ #category : 'accessing' }
MCPEvaluateRequest >> frame [

	^ frame
]

{ #category : 'accessing' }
MCPEvaluateRequest >> frame: aString [

	frame := aString
]

{ #category : 'initialization' }
MCPEvaluateRequest >> initializeCode: aString [

	code := aString.
	^ self
]
