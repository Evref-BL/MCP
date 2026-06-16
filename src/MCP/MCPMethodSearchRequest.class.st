"
Parsed, validated method search request derived from one MCPToolRequest. It contains scope, text filters, pagination, and source-inclusion state shared by method metadata, source, reference, implementor, sender, variable, and equivalence search tools.
"
Class {
	#name : 'MCPMethodSearchRequest',
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
MCPMethodSearchRequest class >> fromMetadataRequest: request tool: aTool [

	| searchRequest |
	searchRequest := self fromRequest: request tool: aTool.
	searchRequest fieldFilters: (aTool
			 fieldFiltersFromRequest: request
			 fieldNames: aTool metadataFilterFieldNames).
	^ searchRequest
]

{ #category : 'instance creation' }
MCPMethodSearchRequest class >> fromRequest: request tool: aTool [

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
		  limit: (request
				   nonNegativeIntegerArgumentNamed: 'limit'
				   default: aTool defaultPageLimit);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> caseSensitive: aBoolean [

	caseSensitive := aBoolean
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> filterMode: aString [

	filterMode := aString
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> filterPattern [

	^ filterPattern
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> filterPattern: aString [

	filterPattern := aString
]

{ #category : 'testing' }
MCPMethodSearchRequest >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'testing' }
MCPMethodSearchRequest >> hasFilterPattern [

	^ filterPattern notNil
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> includeSource [

	^ includeSource
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> includeSource: aBoolean [

	includeSource := aBoolean
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> offset: anInteger [

	offset := anInteger
]

{ #category : 'validating' }
MCPMethodSearchRequest >> requiredFilterPatternForTool: aTool [

	filterPattern ifNil: [
			^ MCPInvalidToolInput
				  signalMissingRequiredArgumentNamed: 'filter'
				  forTool: aTool ].
	filterPattern isEmpty ifTrue: [
			^ MCPInvalidToolInput
				  signalMissingRequiredArgumentNamed: 'filter'
				  forTool: aTool ].
	^ filterPattern
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> scopeQuery: anObject [

	scopeQuery := anObject
]

{ #category : 'accessing' }
MCPMethodSearchRequest >> warnings [

	^ self scopeQuery warnings
]
