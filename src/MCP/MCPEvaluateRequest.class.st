"
Parsed evaluate tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPEvaluateRequest',
	#superclass : 'Object',
	#instVars : [
		'code'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPEvaluateRequest class >> fromRequest: aRequest tool: aTool [

	^ self new initializeCode: (aRequest stringArgumentNamed: 'code')
]

{ #category : 'accessing' }
MCPEvaluateRequest >> code [

	^ code
]

{ #category : 'initialization' }
MCPEvaluateRequest >> initializeCode: aString [

	code := aString.
	^ self
]
