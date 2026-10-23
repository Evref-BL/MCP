"
Shared implementation for Iceberg repository operation tools.

It defines per-tool repository inputs, dispatches repository commands, and returns structured repository operation results for create, attach, update, identity verification, diff, export, commit, branch, and remote actions.
"
Class {
	#name : 'MCPToolRepositoryOperation',
	#superclass : 'MCPToolMutation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRepositoryOperation class >> groupName [

	^ self repositoriesGroupName
]

{ #category : 'testing' }
MCPToolRepositoryOperation class >> isAbstract [

	^ self = MCPToolRepositoryOperation
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> additionalKeywords [

	^ #( 'repository' 'repo' 'iceberg' 'git' )
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> branchNameSchemaProperty [

	^ self schemaPropertyNamed: 'branch' type: 'string' description: 'Branch name.'
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> commandClass [

	^ self repositoryToolSpec at: #commandClass
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> commandForRequest: repositoryRequest [

	^ self commandClass tool: self request: repositoryRequest
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryResult: aResult [

	^ aResult asDictionary
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> description [

	^ self repositoryToolSpec at: #description
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> errorResultForCommandError: anError action: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value | value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	details at: #action put: action.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> inputProperties [

	^ (self repositoryToolSpec at: #referenceInputProperties ifAbsent: [ self repositoryReferenceInputProperties ])
	  , (self repositoryToolSpec at: #inputProperties ifAbsent: [ #(  ) ])
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> isModifiedSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'isModified'
		  description: 'Expected repository modified state for repository identity verification.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> messageSchemaProperty [

	^ self schemaPropertyNamed: 'message' type: 'string' description: 'Commit message for the repository commit.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> modifiedPackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'modifiedPackages'
		  description: 'Expected modified package names for repository identity verification.'
		  itemDescription: 'An expected modified package name.'
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ self operationAction
]

{ #category : 'private - actions' }
MCPToolRepositoryOperation >> operationAction [

	^ self repositoryToolSpec at: #action
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> packageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'packages'
		  description: 'Expected managed package names for repository identity verification.'
		  itemDescription: 'An expected package name.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ self requestClass fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryReferenceInputProperties [

	^ {
		  (self schemaPropertyNamed: 'name' type: 'string' description: 'Registered repository name.').
		  (self schemaPropertyNamed: 'location' type: 'string' description: 'Repository location disambiguator.') }
]

{ #category : 'private - specs' }
MCPToolRepositoryOperation >> repositoryToolSpec [

	self subclassResponsibility
]

{ #category : 'private - execution' }
MCPToolRepositoryOperation >> requestClass [

	^ self repositoryToolSpec at: #requestClass
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> requiredInputProperties [

	^ self repositoryToolSpec at: #requiredProperties ifAbsent: [ #( 'name' ) ]
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> subdirectorySchemaProperty [

	^ self
		  schemaPropertyNamed: 'subdirectory'
		  type: 'string'
		  description:
		  'Repository source subdirectory. For attaching or updating an unborn repository, omit until an initial commit/head exists.'
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> title [

	^ self repositoryToolSpec at: #title
]
