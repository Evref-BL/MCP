"
Shared implementation for Iceberg repository operation tools.

It defines per-tool repository inputs, dispatches repository commands, and returns structured repository operation results for create, attach, update, identity verification, diff, export, commit, branch, and remote actions.
"
Class {
	#name : 'MCPToolRepositoryOperation',
	#superclass : 'MCPToolMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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
	"A guard, not a checkout: both tools that take it refuse to act when the repository is on another branch."

	^ self
		  schemaPropertyNamed: 'branch'
		  type: 'string'
		  description: 'Branch the repository is expected to be on. The call fails if it is on another; it never switches branch.'
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
		  description: 'Assert whether the image holds changes the repository files do not.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> messageSchemaProperty [

	^ self schemaPropertyNamed: 'message' type: 'string' description: 'Commit message for the repository commit.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> modifiedPackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'modifiedPackages'
		  description: 'Assert exactly these managed packages differ from the repository files.'
		  itemDescription: 'Package name.'
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
		  description: 'Assert the repository manages exactly these packages.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ self requestClass fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryReferenceInputProperties [

	^ {
		  (self schemaPropertyNamed: 'name' type: 'string' description: 'Registered repository name.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description: 'Checkout path, to tell apart repositories registered under the same name.') }
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
		  'Directory inside the checkout holding the package sources, such as src. Omit it while the repository has no commit yet.'
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> title [

	^ self repositoryToolSpec at: #title
]
