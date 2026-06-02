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

{ #category : 'testing' }
MCPToolRepositoryOperation class >> isAbstract [

	^ self = MCPToolRepositoryOperation
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> branchNameSchemaProperty [

	^ self
		  schemaPropertyNamed: 'branchName'
		  type: 'string'
		  description:
		  'Branch name for repository_branch_create or repository_branch_switch, or an optional expected current branch guard for repository_head_adopt and repository_identity_verify.'
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
MCPToolRepositoryOperation >> dataForRepositoryAdoptHeadResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'adoptHead'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryAttachResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'attach'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryCommitResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'commit'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryCreateBranchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'createBranch'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryCreateResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'create'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryDiffResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'diff'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryExportResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'export'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryFetchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'fetch'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryPullResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'pull'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryPushResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'push'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryResult: aResult action: actionName [

	| data |
	data := aResult asDictionary copy.
	data at: #action put: actionName.
	^ data
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositorySwitchBranchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'switchBranch'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryUpdateResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'update'
]

{ #category : 'private - results' }
MCPToolRepositoryOperation >> dataForRepositoryVerifyIdentityResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'verifyIdentity'
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultDescription [

	^ self repositoryToolSpec at: #description
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self repositoryOperationDataProperties
		  required: #( 'action' 'repository' 'packages' 'packageNames' )
]

{ #category : 'defaults' }
MCPToolRepositoryOperation >> defaultTitle [

	^ self repositoryToolSpec at: #title
]

{ #category : 'private - errors' }
MCPToolRepositoryOperation >> errorResultForCommandError: anError action: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value |
			value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	details at: #action put: action.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> inputProperties [

	^ (self repositoryToolSpec
		   at: #referenceInputProperties
		   ifAbsent: [ self repositoryReferenceInputProperties ])
	  ,
	  (self repositoryToolSpec
		   at: #inputProperties
		   ifAbsent: [ #(  ) ])
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> isModifiedSchemaProperty [

	^ self
		  booleanSchemaPropertyNamed: 'isModified'
		  description:
		  'Expected repository modified state for repository identity verification.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> messageSchemaProperty [

	^ self
		  schemaPropertyNamed: 'message'
		  type: 'string'
		  description: 'Commit message for the repository commit.'
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> modifiedPackageNamesSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'modifiedPackageNames'
		  description:
		  'Expected modified package names for repository identity verification.'
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
		  description:
		  'Expected managed package names for repository identity verification.'
		  itemDescription: 'An expected package name.'
]

{ #category : 'private - request' }
MCPToolRepositoryOperation >> parsedRequestFromToolRequest: request [

	^ self requestClass fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryOperationDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'action'
			   type: 'string'
			   description:
			   'The repository action executed by this repository tool.').
		  self repositoryOutputSchemaProperty.
		  (self
			   schemaPropertyNamed: 'repositoryBefore'
			   type: 'object'
			   description:
			   'Structured metadata for the repository before the action, when reported.').
		  self repositoryPackagesOutputSchemaProperty.
		  (self
			   stringArraySchemaNamed: 'packageNames'
			   description: 'The repository package names after the action.'
			   itemDescription: 'A package name.').
		  (self
			   stringArraySchemaNamed: 'updateActions'
			   description:
			   'Repository update actions applied when action=update.'
			   itemDescription: 'An update action name.').
		  (self
			   stringArraySchemaNamed: 'addedPackageNames'
			   description:
			   'Package names added to repository membership when action=update.'
			   itemDescription: 'An added package name.').
		  (self
			   stringArraySchemaNamed: 'removedPackageNames'
			   description:
			   'Package names removed from repository membership when action=update.'
			   itemDescription: 'A removed package name.').
		  (self
			   stringArraySchemaNamed: 'changedPackageNames'
			   description:
			   'Package names included in the working-copy diff for action=export, action=diff, or before action=commit.'
			   itemDescription: 'A changed package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNames'
			   description:
			   'Package names reported modified by Iceberg after the action, when relevant.'
			   itemDescription: 'A modified package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNamesBefore'
			   description:
			   'Package names reported modified by Iceberg before action=adoptHead.'
			   itemDescription: 'A modified package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNamesAfter'
			   description:
			   'Package names reported modified by Iceberg after action=adoptHead.'
			   itemDescription: 'A modified package name.').
		  (self
			   stringArraySchemaNamed: 'checkedFields'
			   description:
			   'Repository identity fields checked when action=verifyIdentity.'
			   itemDescription: 'A checked repository identity field.').
		  (self
			   stringArraySchemaNamed: 'modifiedPaths'
			   description:
			   'Relative repository paths included in the working-copy diff when obtainable from Iceberg.'
			   itemDescription: 'A relative repository path.').
		  (self
			   stringArraySchemaNamed: 'restoredOrderOnlyPaths'
			   description:
			   'Relative Tonel class or extension paths restored after export because their only disk change was method order churn.'
			   itemDescription: 'A restored relative repository path.').
		  (self
			   stringArraySchemaNamed: 'remoteNames'
			   description: 'Repository remote names after the action.'
			   itemDescription: 'A remote name.').
		  (self
			   schemaPropertyNamed: 'branchName'
			   type: 'string'
			   description: 'Current branch name after the action.').
		  (self
			   schemaPropertyNamed: 'previousBranchName'
			   type: 'string'
			   description: 'Branch name before a branch action.').
		  (self
			   schemaPropertyNamed: 'previousHeadDescription'
			   type: 'string'
			   description: 'Head description before a branch action.').
		  (self
			   schemaPropertyNamed: 'previousReferenceCommitId'
			   type: 'string'
			   description:
			   'Working-copy reference commit id before action=adoptHead.').
		  (self
			   schemaPropertyNamed: 'referenceCommitId'
			   type: 'string'
			   description:
			   'Working-copy reference commit id after action=adoptHead.').
		  (self
			   schemaPropertyNamed: 'adoptedCommitId'
			   type: 'string'
			   description:
			   'Repository head commit id adopted by action=adoptHead.').
		  (self
			   booleanSchemaPropertyNamed: 'didAdopt'
			   description:
			   'Whether action=adoptHead changed the working-copy reference commit.').
		  (self
			   booleanSchemaPropertyNamed: 'didChange'
			   description:
			   'Whether the export diff contained package or path changes.').
		  (self
			   integerSchemaPropertyNamed: 'changeCount'
			   description:
			   'Number of changed paths reported for action=diff, or changed packages when paths are unavailable.').
		  (self
			   booleanSchemaPropertyNamed: 'isEmpty'
			   description:
			   'Whether IceRepository>>workingCopyDiff reported an empty diff for action=diff.').
		  (self
			   booleanSchemaPropertyNamed: 'matched'
			   description:
			   'Whether the repository matched all expected identity fields when action=verifyIdentity.').
		  (self
			   schemaPropertyNamed: 'commitId'
			   type: 'string'
			   description:
			   'Commit identifier returned by Iceberg for action=commit, when available.').
		  (self
			   schemaPropertyNamed: 'commitDescription'
			   type: 'string'
			   description:
			   'Commit description returned by Iceberg for action=commit, when available.').
		  (self
			   schemaPropertyNamed: 'headDescription'
			   type: 'string'
			   description:
			   'Repository head description after the action, when available.').
		  (self
			   schemaPropertyNamed: 'repositoryLocation'
			   type: 'string'
			   description: 'The repository location on disk.') }
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repository'
		            type: 'object'
		            description:
		            'Structured metadata for the repository after the update.'.
	property additionalProperties: true.
	^ property
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryPackageInfoOutputSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured metadata for one package managed by the repository.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'The package name.').
				  (self
					   schemaPropertyNamed: 'directoryName'
					   type: 'string'
					   description: 'The package directory name used by Iceberg.').
				  (self
					   booleanSchemaPropertyNamed: 'isLoaded'
					   description: 'Whether the package is loaded in the image.').
				  (self
					   booleanSchemaPropertyNamed: 'isModified'
					   description:
						   'Whether Iceberg reports image changes for the package.') };
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
		            description:
		            'Packages managed by the repository after the update.'.
	property items: self repositoryPackageInfoOutputSchemaProperty.
	^ property
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> repositoryReferenceInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'repositoryName'
			   type: 'string'
			   description: 'Registered repository name to target.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description:
			   'Optional filesystem path used with repositoryName to disambiguate or guard the selected registered repository.') }
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

	^ self repositoryToolSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'repositoryName' ) ]
]

{ #category : 'testing' }
MCPToolRepositoryOperation >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	| action data |
	data := self
		        successfulStructuredDataFromResult: aResult
		        ifAbsent: [ ^ false ].
	action := data
		          at: #action
		          ifAbsent: [
		          ^ self shouldSaveImageAfterSuccessfulExecution ].
	^ (#( 'diff' 'verifyIdentity' ) includes: action) not
]

{ #category : 'private - schema' }
MCPToolRepositoryOperation >> subdirectorySchemaProperty [

	^ self
		  schemaPropertyNamed: 'subdirectory'
		  type: 'string'
		  description:
		  'Expected source subdirectory for repository identity verification. Empty string is accepted.'
]

{ #category : 'validating' }
MCPToolRepositoryOperation >> validateRequest: request [

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
