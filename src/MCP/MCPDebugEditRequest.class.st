Class {
	#name : 'MCPDebugEditRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'methodSource'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugEditRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  operation: 'edit';
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  methodSource: (aRequest stringArgumentNamed: 'methodSource');
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

{ #category : 'accessing' }
MCPDebugEditRequest >> methodSource [

	^ methodSource
]

{ #category : 'accessing' }
MCPDebugEditRequest >> methodSource: aString [

	methodSource := aString
]
