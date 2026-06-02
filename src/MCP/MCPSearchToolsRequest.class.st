"
Request object for tool catalog searches.

It captures the optional search text, group filter, static-tool inclusion flag, and result limit used by tool_search.
"
Class {
	#name : 'MCPSearchToolsRequest',
	#superclass : 'Object',
	#instVars : [
		'query',
		'group',
		'includeStatic',
		'limit'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPSearchToolsRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  query: (aToolRequest stringArgumentNamed: 'query');
		  group: (aToolRequest stringArgumentNamed: 'group');
		  includeStatic:
			  (aToolRequest
				   booleanArgumentNamed: 'includeStatic'
				   default: false);
		  limit:
			  (aToolRequest
				   nonNegativeIntegerArgumentNamed: 'limit'
				   default: 100);
		  yourself
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> group [

	^ group
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> group: anObject [

	group := anObject
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> includeStatic [

	^ includeStatic
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> includeStatic: aBoolean [

	includeStatic := aBoolean
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query [

	^ query
]

{ #category : 'accessing' }
MCPSearchToolsRequest >> query: anObject [

	query := anObject
]
