"
Command that returns method source and optional variable-reference DTOs for method_get.
"
Class {
	#name : 'MCPGetMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPGetMethodCommand >> execute [

	| compiledMethod data methodBehavior protocolName variableReferences |
	compiledMethod := tool methodForClassNamed: request className selector: request selectorString classSide: request classSide.
	protocolName := compiledMethod protocolName ifNil: [ '' ] ifNotNil: [ :protocol | protocol asString ].
	data := {
		        (#protocol -> protocolName).
		        (#source -> (compiledMethod sourceCode ifNil: [ '' ])) } asDictionary.
	(MCPCompiledMethodInfo fromMethod: compiledMethod) traitName ifNotNil: [ :traitName | data at: #trait put: traitName ].
	request includeVariableDetails ifTrue: [
			methodBehavior := tool behaviorNamed: request className classSide: request classSide.
			variableReferences := tool variableSummariesForMethod: compiledMethod methodBehavior: methodBehavior.
			data at: #variableReferences put: variableReferences ].
	^ MCPGetMethodResult data: data externalVariableCount: nil
]
