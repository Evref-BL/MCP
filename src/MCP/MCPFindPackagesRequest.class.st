"
Parsed, validated package_search request derived from one MCPToolRequest. It keeps package query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPFindPackagesRequest',
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
MCPFindPackagesRequest class >> fromRequest: request tool: aTool [

	| scopeQuery |
	scopeQuery := MCPPackageScopeQuery new
		              projectNames:
			              (request stringCollectionArgumentNamed:
					               'projectNames');
		              packageNames:
			              (request stringCollectionArgumentNamed:
					               'packageNames');
		              yourself.
	^ self new
		  scopeQuery: scopeQuery;
		  filterMode: (aTool filterModeFromRequest: request);
		  fieldFilters: (aTool
				   fieldFiltersFromRequest: request
				   fieldNames: aTool packageFilterFieldNames);
		  caseSensitive:
			  (request booleanArgumentNamed: 'caseSensitive' default: true);
		  limit:
			  (request nonNegativeIntegerArgumentNamed: 'limit' default: 100);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> caseSensitive: anObject [

	caseSensitive := anObject
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'testing' }
MCPFindPackagesRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> limit: anObject [

	limit := anObject
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> offset: anObject [

	offset := anObject
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]
