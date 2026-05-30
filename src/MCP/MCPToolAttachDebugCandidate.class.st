Class {
	#name : 'MCPToolAttachDebugCandidate',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAttachDebugCandidate class >> toolName [

	^ 'debug_candidate_attach'
]

{ #category : 'private - operations' }
MCPToolAttachDebugCandidate >> sessionOperationSpec [

	^ {
		  (#title -> 'Attach Debug Candidate').
		  (#description
		   ->
		   'Attach an open Pharo debugger candidate to the MCP debugger registry and return its session state.').
		  (#operation -> 'attach').
		  (#inputProperties -> { self candidateRefSchemaProperty }).
		  (#requiredProperties -> #( 'candidateRef' )) } asDictionary
]
