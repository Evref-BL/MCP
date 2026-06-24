"
Command that returns method source and optional variable-reference DTOs for method_get.
"
Class {
	#name : 'MCPGetMethodCommand',
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
MCPGetMethodCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPGetMethodCommand >> execute [

	| compiledMethod data methodBehavior protocolName variableReferences |
	compiledMethod := tool
		                  methodForClassNamed: request className
		                  selector: request selectorString
		                  classSide: request classSide.
	protocolName := compiledMethod protocol
		                ifNil: [ '' ]
		                ifNotNil: [ :protocol | protocol name asString ].
	data := {
		        (#protocol -> protocolName).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) }
		        asDictionary.
	request includeVariableDetails ifTrue: [
		methodBehavior := tool
			                  behaviorNamed: request className
			                  classSide: request classSide.
		variableReferences := tool
			                      variableSummariesForMethod: compiledMethod
			                      methodBehavior: methodBehavior.
		data at: #variableReferences put: variableReferences ].
	^ MCPGetMethodResult data: data externalVariableCount: nil
]

{ #category : 'initialization' }
MCPGetMethodCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'accessing' }
MCPGetMethodCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPGetMethodCommand >> tool [

	^ tool
]
