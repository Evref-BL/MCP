"
Parsed, validated find-classes request derived from one MCPToolRequest. It keeps class query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPFindClassesRequest',
	#superclass : 'Object',
	#instVars : [
		'filterPattern',
		'filterTargets',
		'filterMode',
		'caseSensitive',
		'limit',
		'offset',
		'scopeQuery',
		'whereSpec'
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
		  filterPattern: (request stringArgumentNamed: 'filter');
		  filterTargets: (aTool filterTargetsFromRequest: request);
		  filterMode: (aTool filterModeFromRequest: request);
		  whereSpec: (MCPWhereSpec fromToolRequest: request);
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
MCPFindClassesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterPattern [

	^ filterPattern
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterPattern: anObject [

	filterPattern := anObject
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterTargets [

	^ filterTargets
]

{ #category : 'accessing' }
MCPFindClassesRequest >> filterTargets: anObject [

	filterTargets := anObject
]

{ #category : 'testing' }
MCPFindClassesRequest >> hasFilterPattern [

	^ filterPattern notNil
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

{ #category : 'accessing' }
MCPFindClassesRequest >> whereSpec [

	^ whereSpec ifNil: [ MCPWhereSpec absent ]
]

{ #category : 'accessing' }
MCPFindClassesRequest >> whereSpec: anObject [

	whereSpec := anObject
]
