"
Command that inspects method source and optional variable-reference DTOs for inspect-method.
"
Class {
	#name : 'MCPInspectMethodCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPInspectMethodCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPInspectMethodCommand >> execute [

	| compiledMethod data methodBehavior protocolName variableReferences |
	compiledMethod := tool
		                  methodForClassNamed: request className
		                  selector: request selectorString
		                  side: request side.
	protocolName := compiledMethod protocol
		                ifNil: [ '' ]
		                ifNotNil: [ :protocol | protocol name asString ].
	data := {
		        (#protocol -> protocolName).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) }
		        asDictionary.
	request includeVariableDetails ifTrue: [
		methodBehavior := tool
			                  methodBehaviorForClassNamed: request className
			                  side: request side.
		variableReferences := tool
			                      variableSummariesForMethod: compiledMethod
			                      methodBehavior: methodBehavior.
		data at: #variableReferences put: variableReferences ].
	^ {
		  (#data -> data).
		  (#externalVariableCount -> nil) } asDictionary
]

{ #category : 'initialization' }
MCPInspectMethodCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPInspectMethodCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPInspectMethodCommand >> tool [

	^ tool
]
