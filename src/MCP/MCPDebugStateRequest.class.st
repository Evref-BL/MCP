"
Request object for the primary debug_state_get snapshot.

It currently uses only the common debugger request fields but remains separate so debug_state_get can evolve without changing other debugger requests.
"
Class {
	#name : 'MCPDebugStateRequest',
	#superclass : 'MCPDebugRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugStateRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  operation: 'state';
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  sourceContextLines: (aRequest
				   nonNegativeIntegerArgumentNamed: 'sourceContextLines'
				   default: self defaultSourceContextLines);
		  stackStart: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackStart'
				   default: self defaultStackStart);
		  stackLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'stackLimit'
				   default: self defaultStackLimit);
		  variableDepth: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableDepth'
				   default: self defaultVariableDepth);
		  variableLimit: (aRequest
				   nonNegativeIntegerArgumentNamed: 'variableLimit'
				   default: self defaultVariableLimit);
		  includeReceiver: (aRequest
				   booleanArgumentNamed: 'includeReceiver'
				   default: self defaultIncludeReceiver);
		  yourself
]
