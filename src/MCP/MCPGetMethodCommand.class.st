"
Command that returns method source and optional variable-reference DTOs for method_get.
"
Class {
	#name : 'MCPGetMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPGetMethodCommand >> execute [

	| compiledMethod data methodBehavior protocolName variableReferences |
	compiledMethod := tool methodForClassNamed: request className selector: request selectorString classSide: request classSide.
	protocolName := compiledMethod protocol ifNil: [ '' ] ifNotNil: [ :protocol | protocol name asString ].
	data := {
		        (#protocol -> protocolName).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) } asDictionary.
	request includeVariableDetails ifTrue: [
			methodBehavior := tool behaviorNamed: request className classSide: request classSide.
			variableReferences := tool variableSummariesForMethod: compiledMethod methodBehavior: methodBehavior.
			data at: #variableReferences put: variableReferences ].
	^ MCPGetMethodResult data: data externalVariableCount: nil
]
