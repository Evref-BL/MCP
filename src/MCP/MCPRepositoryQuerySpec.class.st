"
Parsed repository_search query spec derived from one MCPToolRequest.

It keeps repository query execution away from raw argument dictionaries and distinguishes omitted optional boolean filters from explicit true or false filters.
"
Class {
	#name : 'MCPRepositoryQuerySpec',
	#superclass : 'Object',
	#instVars : [
		'isModified',
		'isMissing',
		'fieldFilters',
		'filterMode',
		'limit',
		'offset'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryQuerySpec class >> fromRequest: request tool: aTool [

	^ self new
		  isModified: (self optionalBooleanArgumentNamed: 'isModified' fromRequest: request);
		  isMissing: (self optionalBooleanArgumentNamed: 'isMissing' fromRequest: request);
		  fieldFilters: (aTool fieldFiltersFromRequest: request fieldNames: aTool repositoryFilterFieldNames);
		  filterMode: (aTool filterModeFromRequest: request);
		  limit: (request nonNegativeIntegerArgumentNamed: 'limit' default: aTool defaultPageLimit);
		  offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'private' }
MCPRepositoryQuerySpec class >> optionalBooleanArgumentNamed: anArgumentName fromRequest: request [

	(request hasArgumentNamed: anArgumentName) ifFalse: [ ^ nil ].
	^ request booleanArgumentNamed: anArgumentName default: false
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> fieldFilters [

	^ fieldFilters ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> fieldFilters: aDictionary [

	fieldFilters := aDictionary
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterMode: aString [

	filterMode := aString
]

{ #category : 'testing' }
MCPRepositoryQuerySpec >> hasFieldFilters [

	^ self fieldFilters notEmpty
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> isMissing [

	^ isMissing
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> isMissing: aBooleanOrNil [

	isMissing := aBooleanOrNil
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> isModified [

	^ isModified
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> isModified: aBooleanOrNil [

	isModified := aBooleanOrNil
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> offset: anInteger [

	offset := anInteger
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> warnings [

	^ #(  )
]
