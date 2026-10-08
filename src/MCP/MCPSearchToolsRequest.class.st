"
Request object for tool catalog searches. Captures optional search text and continuation cursor used by tool_search.
"
Class {
	#name : 'MCPSearchToolsRequest',
	#superclass : 'Object',
	#instVars : [
		'query',
		'cursor'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'private' }
MCPSearchToolsRequest class >> cursorFromToolRequest: aToolRequest [

	| cursorString |
	cursorString := aToolRequest stringArgumentNamed: 'cursor'.
	cursorString ifNil: [ ^ 0 ].
	(cursorString allSatisfy: [ :each | each isDigit ]) ifTrue: [ ^ cursorString asInteger ].
	Error signal: 'cursor must be a non-negative integer string.'
]

{ #category : 'instance creation' }
MCPSearchToolsRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  query: (aToolRequest stringArgumentNamed: 'query');
		  cursor: (self cursorFromToolRequest: aToolRequest);
		  yourself
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> cursor [

	^ cursor
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> cursor: anInteger [

	cursor := anInteger
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query [

	^ query
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query: anObject [

	query := anObject
]
