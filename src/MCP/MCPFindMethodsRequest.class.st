"
Parsed, validated method metadata and focused method lookup request derived from one MCPToolRequest. It keeps query execution away from raw argument dictionaries while preserving MCPToolRequest as the transport/schema boundary.
"
Class {
	#name : 'MCPFindMethodsRequest',
	#superclass : 'Object',
	#instVars : [
		'filterPattern',
		'filterMode',
		'caseSensitive',
		'includeSource',
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
MCPFindMethodsRequest class >> fromMetadataRequest: request tool: aTool [

	| queryRequest |
	queryRequest := self fromRequest: request tool: aTool.
	queryRequest fieldFilters: (aTool
			 fieldFiltersFromRequest: request
			 fieldNames: aTool metadataFilterFieldNames).
	^ queryRequest
]

{ #category : 'instance creation' }
MCPFindMethodsRequest class >> fromRequest: request tool: aTool [

	| scopeQuery |
	scopeQuery := aTool methodScopeQueryFromRequest: request.
	^ self new
		  scopeQuery: scopeQuery;
		  filterPattern: (aTool filterPatternFromRequest: request);
		  filterMode: (aTool filterModeFromRequest: request);
		  caseSensitive:
			  (request booleanArgumentNamed: 'caseSensitive' default: true);
		  includeSource:
			  (request booleanArgumentNamed: 'includeSource' default: false);
		  limit:
			  (request nonNegativeIntegerArgumentNamed: 'limit' default: 100);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> caseSensitive: aBoolean [

	caseSensitive := aBoolean
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterMode: aString [

	filterMode := aString
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterPattern [

	^ filterPattern
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterPattern: aString [

	filterPattern := aString
]

{ #category : 'testing' }
MCPFindMethodsRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'testing' }
MCPFindMethodsRequest >> hasFilterPattern [

	^ filterPattern notNil
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> includeSource [

	^ includeSource
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> includeSource: aBoolean [

	includeSource := aBoolean
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> offset: anInteger [

	offset := anInteger
]

{ #category : 'validating' }
MCPFindMethodsRequest >> requiredFilterPatternForTool: aTool [

	(filterPattern isNil or: [ filterPattern isEmpty ]) ifTrue: [
		^ MCPInvalidToolInput
			  signalMissingRequiredArgumentNamed: 'filter'
			  forTool: aTool ].
	^ filterPattern
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]
