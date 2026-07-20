"
Concrete debug_candidate_search tool. It searches unattached open debugger windows that can be attached to the MCP debugger registry through MCPToolDebugSessionOperation.
"
Class {
	#name : 'MCPToolSearchDebugCandidates',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchDebugCandidates class >> toolName [

	^ 'debug_candidate_search'
]

{ #category : 'metadata' }
MCPToolSearchDebugCandidates >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - specs' }
MCPToolSearchDebugCandidates >> sessionToolSpec [

	^ {
		  (#title -> 'Search Debug Candidates').
		  (#description
		   ->
		   'Search unattached open Pharo debugger windows that can be attached to MCP debugging.').
		  (#action -> 'search') } asDictionary
]
