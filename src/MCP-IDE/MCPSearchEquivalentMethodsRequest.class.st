"
Parsed method-equivalence search request. It extends the shared method lookup request with the compiled reference method used for AST-equivalence matching.
"
Class {
	#name : 'MCPSearchEquivalentMethodsRequest',
	#superclass : 'MCPMethodSearchRequest',
	#instVars : [
		'referenceMethod'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPSearchEquivalentMethodsRequest class >> fromRequest: request tool: aTool [

	| searchRequest |
	searchRequest := super fromRequest: request tool: aTool.
	searchRequest referenceMethod: (aTool methodReferenceSpecFromToolRequest: request) compiledMethod.
	^ searchRequest
]

{ #category : 'accessing' }
MCPSearchEquivalentMethodsRequest >> referenceMethod [

	^ referenceMethod
]

{ #category : 'accessing' }
MCPSearchEquivalentMethodsRequest >> referenceMethod: aCompiledMethod [

	referenceMethod := aCompiledMethod
]
