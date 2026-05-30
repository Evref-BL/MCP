"
Request object for catalog discovery.

It captures the optional search text, group filter, static-tool inclusion flag, and result limit used by tool_search.
"
Class {
	#name : 'MCPDiscoverToolsRequest',
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
MCPDiscoverToolsRequest class >> fromToolRequest: aToolRequest [

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
MCPDiscoverToolsRequest >> group [

	^ group
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> group: anObject [

	group := anObject
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> includeStatic [

	^ includeStatic
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> includeStatic: aBoolean [

	includeStatic := aBoolean
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> query [

	^ query
]

{ #category : 'accessing' }
MCPDiscoverToolsRequest >> query: anObject [

	query := anObject
]
