"
Parsed, validated class_search request derived from one MCPToolRequest. It keeps class query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPFindClassesRequest',
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
MCPFindClassesRequest class >> fromRequest: request tool: aTool [

	| scopeQuery |
	scopeQuery := MCPClassScopeQuery new
		              packageNames:
			              (request stringCollectionArgumentNamed:
					               'packageNames');
		              classNames:
			              (request stringCollectionArgumentNamed: 'classNames');
		              hierarchyClassNames:
			              (request stringCollectionArgumentNamed:
					               'hierarchyClassNames');
		              subclassClassNames:
			              (request stringCollectionArgumentNamed:
					               'subclassClassNames');
		              parentClassNames:
			              (request stringCollectionArgumentNamed:
					               'parentClassNames');
		              yourself.
	^ self new
		  scopeQuery: scopeQuery;
		  filterMode: (aTool filterModeFromRequest: request);
		  fieldFilters: (aTool
				   fieldFiltersFromRequest: request
				   fieldNames: aTool classFilterFieldNames);
		  caseSensitive:
			  (request booleanArgumentNamed: 'caseSensitive' default: true);
		  limit:
			  (request nonNegativeIntegerArgumentNamed: 'limit' default: 100);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPFindClassesRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPFindClassesRequest >> caseSensitive: anObject [

	caseSensitive := anObject
]

{ #category : 'accessing' }
MCPFindClassesRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPFindClassesRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'testing' }
MCPFindClassesRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'accessing' }
MCPFindClassesRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPFindClassesRequest >> limit: anObject [

	limit := anObject
]

{ #category : 'accessing' }
MCPFindClassesRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPFindClassesRequest >> offset: anObject [

	offset := anObject
]

{ #category : 'accessing' }
MCPFindClassesRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPFindClassesRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]
