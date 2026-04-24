"
Parsed, validated find-packages request derived from one MCPToolRequest. It keeps package query execution away from raw argument dictionaries.
"
Class {
	#name : 'MCPFindPackagesRequest',
	#superclass : 'Object',
	#instVars : [
		'scopeQuery',
		'filterPattern',
		'filterTargets',
		'filterMode',
		'caseSensitive',
		'limit',
		'offset'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPFindPackagesRequest class >> fromRequest: request tool: aTool [

	| scopeQuery |
	scopeQuery := MCPPackageScopeQuery
		              scope:
		              (request stringArgumentNamed: 'scope' default: 'image')
		              projectNames:
		              (request stringCollectionArgumentNamed: 'projectNames').
	^ self new
		  scopeQuery: scopeQuery;
		  filterPattern: (request stringArgumentNamed: 'filter');
		  filterTargets: (aTool filterTargetsFromRequest: request);
		  filterMode: (aTool filterModeFromRequest: request);
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
MCPFindPackagesRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterMode: anObject [

	filterMode := anObject
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterPattern [

	^ filterPattern
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterPattern: anObject [

	filterPattern := anObject
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterTargets [

	^ filterTargets
]

{ #category : 'accessing' }
MCPFindPackagesRequest >> filterTargets: anObject [

	filterTargets := anObject
]

{ #category : 'testing' }
MCPFindPackagesRequest >> hasFilterPattern [

	^ filterPattern notNil
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
