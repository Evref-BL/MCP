"
Parsed input for debug_watch.

It carries the methods to probe, the variables to watch inside them, and the expression to run while the probes are installed. Both method and variable accept one value or a list.
"
Class {
	#name : 'MCPDebugWatchRequest',
	#superclass : 'Object',
	#instVars : [
		'methodReferences',
		'variableNames',
		'expression'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugWatchRequest class >> fromRequest: aRequest tool: aTool [

	| references |
	references := (aRequest stringCollectionArgumentNamed: 'method') collect: [ :each |
		              (MCPMethodReference fromString: each) ifNil: [
			              MCPCommandError
				              signalErrorCode: #MethodReferenceUnreadable
				              message: 'Could not read ' , each printString , ' as a method. ' , MCPMethodReference helpText
				              details: { (#method -> each) } asDictionary ] ].
	references ifEmpty: [
		MCPCommandError
			signalErrorCode: #DebugWatchTargetMissing
			message: 'debug_watch needs at least one method to probe.'
			details: Dictionary new ].
	^ self new
		  methodReferences: references;
		  variableNames: (aRequest stringCollectionArgumentNamed: 'variable');
		  expression: (aRequest stringArgumentNamed: 'run');
		  yourself
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> expression [

	^ expression
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> expression: aString [

	expression := aString
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> methodReferences [

	^ methodReferences ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> methodReferences: aCollection [

	methodReferences := aCollection
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> variableNames [

	^ variableNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPDebugWatchRequest >> variableNames: aCollection [

	variableNames := aCollection
]

{ #category : 'testing' }
MCPDebugWatchRequest >> watchesVariables [

	^ self variableNames isNotEmpty
]
