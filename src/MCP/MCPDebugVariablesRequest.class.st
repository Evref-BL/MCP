"
Request object for expanding debugger variables.

It carries the opaque variable reference plus flags controlling indexed children and instance-variable expansion.
"
Class {
	#name : 'MCPDebugVariablesRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'variableRef',
		'variableReference',
		'includeIndexed',
		'includeInstanceVariables'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugVariablesRequest class >> fromRequest: aRequest tool: aTool [

	| reference suppliedStateId |
	reference := MCPDebugVariableReference fromString:
		             (aRequest stringArgumentNamed: 'variableRef').
	suppliedStateId := aRequest stringArgumentNamed: 'stateId'.
	suppliedStateId ifNotNil: [ :requestedStateId |
			requestedStateId ~= reference stateId ifTrue: [
					MCPCommandError
						signalErrorCode: #DebugStateStale
						message: 'Debug state ' , requestedStateId
							, ' does not match variable reference state '
							, reference stateId , '.'
						details: {
								(#requestedStateId -> requestedStateId).
								(#referenceStateId -> reference stateId).
								(#variableRef -> reference rawReference) } asDictionary ] ].
	^ self new
		  variableRef: reference rawReference;
		  variableReference: reference;
		  sessionId: reference sessionId;
		  stateId: reference stateId;
		  frameRef:
			  reference sessionId , '/' , reference stateId , '/frame-'
			  , reference frameIndex asString;
		  stackStart: 0;
		  stackLimit: reference frameIndex + 1;
		  variableDepth:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: 1);
		  variableLimit:
			  (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: 50);
		  includeIndexed:
			  (aRequest booleanArgumentNamed: 'includeIndexed' default: true);
		  includeInstanceVariables: (aRequest
				   booleanArgumentNamed: 'includeInstanceVariables'
				   default: true);
		  yourself
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> includeIndexed [

	^ includeIndexed ifNil: [ true ]
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> includeIndexed: aBoolean [

	includeIndexed := aBoolean
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> includeInstanceVariables [

	^ includeInstanceVariables ifNil: [ true ]
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> includeInstanceVariables: aBoolean [

	includeInstanceVariables := aBoolean
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> requestedStateId [

	^ super requestedStateId ifNil: [
			  self variableRef ifNotNil: [ :reference |
				  self stateIdFromReference: reference ] ]
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> variableRef [

	^ variableRef
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> variableRef: aString [

	variableRef := aString
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> variableReference [

	^ variableReference
]

{ #category : 'accessing' }
MCPDebugVariablesRequest >> variableReference: aReference [

	variableReference := aReference
]
