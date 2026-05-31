"
Parsed method-equivalence search request. It extends the shared method lookup request with the compiled reference method used for AST-equivalence matching.
"
Class {
	#name : 'MCPFindEquivalentMethodsRequest',
	#superclass : 'MCPFindMethodsRequest',
	#instVars : [
		'referenceMethod'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPFindEquivalentMethodsRequest class >> fromRequest: request tool: aTool [

	| queryRequest |
	queryRequest := super fromRequest: request tool: aTool.
	queryRequest referenceMethod:
		(aTool methodReferenceSpecFromToolRequest: request) compiledMethod.
	^ queryRequest
]

{ #category : 'accessing' }
MCPFindEquivalentMethodsRequest >> referenceMethod [

	^ referenceMethod
]

{ #category : 'accessing' }
MCPFindEquivalentMethodsRequest >> referenceMethod: aCompiledMethod [

	referenceMethod := aCompiledMethod
]
