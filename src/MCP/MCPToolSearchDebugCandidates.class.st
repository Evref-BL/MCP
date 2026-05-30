Class {
	#name : 'MCPToolSearchDebugCandidates',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSearchDebugCandidates class >> toolName [

	^ 'debug_candidate_search'
]

{ #category : 'private - operations' }
MCPToolSearchDebugCandidates >> sessionOperationSpec [

	^ {
		  (#title -> 'Search Debug Candidates').
		  (#description
		   ->
		   'Search unattached open Pharo debugger windows that can be attached to MCP debugging.').
		  (#operation -> 'discover') } asDictionary
]
