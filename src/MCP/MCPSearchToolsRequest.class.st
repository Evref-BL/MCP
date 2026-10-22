"
Request object for tool catalog searches. Captures the optional search text used by tool_search.
"
Class {
	#name : 'MCPSearchToolsRequest',
	#superclass : 'Object',
	#instVars : [
		'query'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPSearchToolsRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  query: (aToolRequest stringArgumentNamed: 'query');
		  yourself
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query [

	^ query
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query: anObject [

	query := anObject
]
