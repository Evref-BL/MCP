"
Request object for debugger-driven method creation or recompilation.

It carries optional replacement source and the ignoreCritiques flag that lets a caller explicitly proceed despite method critique feedback.
"
Class {
	#name : 'MCPUpdateDebugMethodRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'methodSource',
		'ignoreCritiques'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPUpdateDebugMethodRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  operation: 'update';
		  sessionId: (aRequest stringArgumentNamed: 'sessionId');
		  stateId: (aRequest stringArgumentNamed: 'stateId');
		  frameRef: (aRequest stringArgumentNamed: 'frameRef');
		  methodSource:
			  ((aRequest stringArgumentNamed: 'source') ifNotNil: [ :source |
					   source withInternalLineEndings ]);
		  ignoreCritiques:
			  (aRequest booleanArgumentNamed: 'ignoreCritiques' default: false);
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
MCPUpdateDebugMethodRequest >> ignoreCritiques [

	^ ignoreCritiques ifNil: [ false ]
]

{ #category : 'accessing' }
MCPUpdateDebugMethodRequest >> ignoreCritiques: aBoolean [

	ignoreCritiques := aBoolean.
	^ self
]

{ #category : 'accessing' }
MCPUpdateDebugMethodRequest >> methodSource [

	^ methodSource
]

{ #category : 'accessing' }
MCPUpdateDebugMethodRequest >> methodSource: aString [

	methodSource := aString
]

{ #category : 'accessing' }
MCPUpdateDebugMethodRequest >> resultPreviewCharacterLimit [

	^ 1000
]
