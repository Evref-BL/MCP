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

	^ self schemaPropertyNamed: 'branchName' type: 'string' description: 'Branch name.'
]

{ #category : 'metadata' }
MCPToolRepositoryOperation >> buildOutputSchema [

	^ self standardOutputSchemaForDataProperties: self repositoryOperationDataProperties required: #(  )
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
		  stringArraySchemaNamed: 'modifiedPackageNames'
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
		  stringArraySchemaNamed: 'packageNames'
		  description: 'Expected managed package names for repository identity verification.'
		  itemDescription: 'An expected package name.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ self requestClass fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryOperationDataProperties [

	^ {
		  (self booleanSchemaPropertyNamed: 'matched' description: 'Whether identity verification passed.').
		  (self
			   stringArraySchemaNamed: 'updateActions'
			   description: 'Repository update actions applied.'
			   itemDescription: 'Update action.').
		  (self
			   stringArraySchemaNamed: 'addedPackageNames'
			   description: 'Packages added repository membership.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'removedPackageNames'
			   description: 'Packages removed repository membership.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'changedPackageNames'
			   description: 'Packages with changed files.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNames'
			   description: 'Packages still modified after operation.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNamesBefore'
			   description: 'Packages modified before adopt-head.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNamesAfter'
			   description: 'Packages modified after adopt-head.'
			   itemDescription: 'Package name.').
		  (self stringArraySchemaNamed: 'modifiedPaths' description: 'Changed repository paths.' itemDescription: 'Path.').
		  (self
			   stringArraySchemaNamed: 'restoredOrderOnlyPaths'
			   description: 'Tonel paths restored because only method order changed.'
			   itemDescription: 'Path.').
		  (self integerSchemaPropertyNamed: 'changeCount' description: 'Number of changed paths.').
		  (self booleanSchemaPropertyNamed: 'isEmpty' description: 'Whether the repository diff is empty.').
		  (self booleanSchemaPropertyNamed: 'didChange' description: 'Whether export changed files.').
		  (self booleanSchemaPropertyNamed: 'didAdopt' description: 'Whether adopt-head changed image reference.').
		  (self schemaPropertyNamed: 'commitId' type: 'string' description: 'Commit id created by commit operation.').
		  (self schemaPropertyNamed: 'commitDescription' type: 'string' description: 'Commit description created by commit operation.').
		  (self schemaPropertyNamed: 'branchName' type: 'string' description: 'Current branch after operation.').
		  (self schemaPropertyNamed: 'previousBranchName' type: 'string' description: 'Branch before branch operation.').
		  (self schemaPropertyNamed: 'headDescription' type: 'string' description: 'Current HEAD description after operation.').
		  (self schemaPropertyNamed: 'previousHeadDescription' type: 'string' description: 'HEAD description before branch operation.').
		  (self schemaPropertyNamed: 'previousReferenceCommitId' type: 'string' description: 'Reference commit before adopt-head.').
		  (self schemaPropertyNamed: 'referenceCommitId' type: 'string' description: 'Reference commit after adopt-head.').
		  (self schemaPropertyNamed: 'adoptedCommitId' type: 'string' description: 'Commit adopted by adopt-head.') }
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repository'
		            type: 'object'
		            description: 'Structured metadata for the repository after the update.'.
	property additionalProperties: true.
	^ property
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryPackageInfoOutputSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'Structured metadata for one package managed by the repository.';
		  properties: {
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'The package name.').
				  (self schemaPropertyNamed: 'directoryName' type: 'string' description: 'The package directory name used by Iceberg.').
				  (self booleanSchemaPropertyNamed: 'isLoaded' description: 'Whether the package is loaded in the image.').
				  (self booleanSchemaPropertyNamed: 'isModified' description: 'Whether Iceberg reports image changes for the package.') };
		  required: #( 'name' 'directoryName' 'isLoaded' 'isModified' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryPackagesOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'packages'
		            type: 'array'
		            description: 'Packages managed by the repository after the update.'.
	property items: self repositoryPackageInfoOutputSchemaProperty.
	^ property
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

{ #category : 'testing' }
MCPToolRepositoryOperation >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	^ (#( 'diff' 'verifyIdentity' ) includes: self operationAction) not
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
