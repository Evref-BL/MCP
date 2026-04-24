"
Parsed, validated find-methods request derived from one MCPToolRequest. It keeps query execution away from raw argument dictionaries while preserving MCPToolRequest as the transport/schema boundary.
"
Class {
	#name : 'MCPFindMethodsRequest',
	#superclass : 'Object',
	#instVars : [
		'scopeQuery',
		'filterPattern',
		'filterTargets',
		'filterMode',
		'caseSensitive',
		'includeSource',
		'limit',
		'offset'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPFindMethodsRequest class >> fromRequest: request tool: aTool [

	^ self new
		  scopeQuery: (aTool methodScopeQueryFromRequest: request);
		  filterPattern: (request stringArgumentNamed: 'filter');
		  filterMode: (aTool filterModeFromRequest: request);
		  filterTargets: (aTool filterTargetsFromRequest: request);
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

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterTargets [

	^ filterTargets
]

{ #category : 'accessing' }
MCPFindMethodsRequest >> filterTargets: aCollection [

	filterTargets := aCollection
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

{ #category : 'testing' }
MCPFindMethodsRequest >> needsSourceForFiltering [

	^ filterPattern notNil and: [ filterTargets includes: 'source' ]
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

	filterPattern ifNil: [
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
MCPFindMethodsRequest >> scopeQuery: aScopeQuery [

	scopeQuery := aScopeQuery
]

{ #category : 'testing' }
MCPFindMethodsRequest >> usesClassReferenceLookup [

	^ filterMode = 'classReference'
]

{ #category : 'testing' }
MCPFindMethodsRequest >> usesImplementorLookup [

	filterPattern ifNil: [ ^ false ].
	filterMode = 'exact' ifFalse: [ ^ false ].
	caseSensitive ifFalse: [ ^ false ].
	^ filterTargets asArray = #( 'selector' )
]

{ #category : 'testing' }
MCPFindMethodsRequest >> usesSelectorReferenceLookup [

	^ filterMode = 'selectorReference'
]

{ #category : 'testing' }
MCPFindMethodsRequest >> usesVariableReferenceLookup [

	^ filterMode = 'variableReference'
]
