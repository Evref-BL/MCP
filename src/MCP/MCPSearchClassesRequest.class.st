"
Parsed, validated class_search request derived from one MCPToolRequest. It keeps class query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPSearchClassesRequest',
	#superclass : 'Object',
	#instVars : [
		'filterMode',
		'caseSensitive',
		'limit',
		'offset',
		'scopeQuery',
		'fieldFilters'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPSearchClassesRequest class >> fromRequest: request tool: aTool [

	^ self new
		  scopeQuery: (aTool classScopeQueryFromRequest: request);
		  filterMode: (aTool filterModeFromRequest: request);
		  fieldFilters: (aTool fieldFiltersFromRequest: request fieldNames: aTool classFilterFieldNames);
		  caseSensitive: false;
		  limit: (request nonNegativeIntegerArgumentNamed: 'limit' default: aTool defaultPageLimit);
		  offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> caseSensitive: anObject [

	caseSensitive := anObject
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'testing' }
MCPSearchClassesRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> limit: anObject [

	limit := anObject
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> offset: anObject [

	offset := anObject
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]

{ #category : 'accessing' }
MCPSearchClassesRequest >> warnings [

	^ self scopeQuery warnings
]
