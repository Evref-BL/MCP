"
Concrete debug_candidate_attach tool. It attaches an open debugger candidate to the MCP debugger registry through MCPToolDebugSessionOperation.
"
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

{ #category : 'private - specs' }
MCPToolAttachDebugCandidate >> sessionToolSpec [

	^ {
		  (#title -> 'Attach Debug Candidate').
		  (#description
		   ->
		   'Attach an open Pharo debugger candidate to the MCP debugger registry and return its session state.').
		  (#action -> 'attach').
		  (#inputProperties -> { self candidateRefSchemaProperty }).
		  (#requiredProperties -> #( 'candidateRef' )) } asDictionary
]
