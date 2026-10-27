"
Command object used by search tools. It executes a parsed search request against its tool and returns matching entry DTO dictionaries before pagination/output shaping.
"
Class {
	#name : 'MCPSearchToolCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPSearchToolCommand >> execute [

	^ tool queryEntriesForQueryRequest: request
]
