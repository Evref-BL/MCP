"
Parsed, validated package_search request derived from one MCPToolRequest. It keeps package query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPSearchPackagesRequest',
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
MCPSearchPackagesRequest class >> fromRequest: request tool: aTool [

	| scopeQuery |
	scopeQuery := MCPPackageScopeQuery new
		              projectNames: (request stringCollectionArgumentNamed: 'projectNames');
		              packageNames: (request stringCollectionArgumentNamed: 'packageNames');
		              yourself.
	^ self new
		  scopeQuery: scopeQuery;
		  filterMode: (aTool filterModeFromRequest: request);
		  fieldFilters: (aTool fieldFiltersFromRequest: request fieldNames: aTool packageFilterFieldNames);
		  caseSensitive: (request booleanArgumentNamed: 'caseSensitive' default: true);
		  limit: (request nonNegativeIntegerArgumentNamed: 'limit' default: aTool defaultPageLimit);
		  offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> caseSensitive: anObject [

	caseSensitive := anObject
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'testing' }
MCPSearchPackagesRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> limit: anObject [

	limit := anObject
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> offset: anObject [

	offset := anObject
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]

{ #category : 'accessing' }
MCPSearchPackagesRequest >> warnings [

	^ self scopeQuery warnings
]
