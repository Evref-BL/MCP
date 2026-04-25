"
Parsed find-repositories query spec derived from one MCPToolRequest.

It keeps repository query execution away from raw argument dictionaries and distinguishes omitted optional boolean filters from explicit true or false filters.
"
Class {
	#name : 'MCPRepositoryQuerySpec',
	#superclass : 'Object',
	#instVars : [
		'repositoryNames',
		'directoryPaths',
		'packageNames',
		'isModified',
		'isMissing',
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
MCPRepositoryQuerySpec class >> fromRequest: request tool: aTool [

	^ self new
		  repositoryNames:
			  (request uniqueStringCollectionArgumentNamed: 'repositoryNames');
		  directoryPaths:
			  (request uniqueStringCollectionArgumentNamed: 'directoryPaths');
		  packageNames:
			  (request uniqueStringCollectionArgumentNamed: 'packageNames');
		  isModified:
			  (self
				   optionalBooleanArgumentNamed: 'isModified'
				   fromRequest: request);
		  isMissing:
			  (self
				   optionalBooleanArgumentNamed: 'isMissing'
				   fromRequest: request);
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

{ #category : 'private' }
MCPRepositoryQuerySpec class >> optionalBooleanArgumentNamed: anArgumentName fromRequest: request [

	(request hasArgumentNamed: anArgumentName) ifFalse: [ ^ nil ].
	^ request booleanArgumentNamed: anArgumentName default: false
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> caseSensitive [

	^ caseSensitive
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> caseSensitive: aBoolean [

	caseSensitive := aBoolean
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> directoryPaths [

	^ directoryPaths
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> directoryPaths: aCollection [

	directoryPaths := aCollection
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterMode [

	^ filterMode
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterMode: aString [

	filterMode := aString
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterPattern [

	^ filterPattern
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterPattern: aStringOrNil [

	filterPattern := aStringOrNil
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterTargets [

	^ filterTargets
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> filterTargets: aCollection [

	filterTargets := aCollection
]

{ #category : 'testing' }
MCPRepositoryQuerySpec >> hasFilterPattern [

	^ filterPattern notNil
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
MCPRepositoryQuerySpec >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> packageNames: aCollection [

	packageNames := aCollection
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> repositoryNames [

	^ repositoryNames
]

{ #category : 'accessing' }
MCPRepositoryQuerySpec >> repositoryNames: aCollection [

	repositoryNames := aCollection
]
