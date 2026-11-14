"
Parsed evaluate tool request derived from one validated MCPToolRequest.
"
Class {
	#name : 'MCPEvaluateRequest',
	#superclass : 'Object',
	#instVars : [
		'code',
		'timeoutSeconds'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPEvaluateRequest class >> fromRequest: aRequest tool: aTool [

	^ self new initializeCode: (aRequest stringArgumentNamed: 'code') timeoutSeconds: (aRequest
			   nonNegativeIntegerArgumentNamed: 'timeoutSeconds'
			   default: aTool defaultTimeoutSeconds
			   maximum: aTool maximumTimeoutSeconds)
]

{ #category : 'accessing' }
MCPEvaluateRequest >> code [

	^ code
]

{ #category : 'initialization' }
MCPEvaluateRequest >> initializeCode: aString timeoutSeconds: anInteger [

	code := aString.
	timeoutSeconds := anInteger
]

{ #category : 'accessing' }
MCPEvaluateRequest >> timeoutSeconds [
	"How long the code may run before it is stopped."

	^ timeoutSeconds
]
