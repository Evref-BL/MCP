"
Shared implementation for focused Iceberg repository tools. It builds repository command requests, dispatches repository commands, and returns structured repository edit results for create, attach, update, identity verification, diff, export, commit, branch, and remote actions.
"
Class {
	#name : 'MCPToolEditRepository',
	#superclass : 'MCPToolEdit',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolEditRepository class >> isAbstract [

	^ self = MCPToolEditRepository
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryAdoptHeadResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'adoptHead'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryAttachResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'attach'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryCommitResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'commit'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryCreateBranchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'createBranch'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryCreateResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'create'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryDiffResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'diff'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryExportResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'export'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryFetchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'fetch'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryPullResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'pull'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryPushResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'push'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryResult: aResult action: actionName [

	| data |
	data := aResult asDictionary copy.
	data at: #action put: actionName.
	^ data
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositorySwitchBranchResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'switchBranch'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryUpdateResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'update'
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryVerifyIdentityResult: aResult [

	^ self dataForRepositoryResult: aResult action: 'verifyIdentity'
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self repositoryEditDataProperties
		  required: #( 'action' 'repository' 'packages' 'packageNames' )
]

{ #category : 'private - errors' }
MCPToolEditRepository >> errorResultForCommandError: anError operation: action requestedContext: requestedContext [

	| details |
	details := anError structuredDetails copy.
	requestedContext ifNotNil: [
		requestedContext keysAndValuesDo: [ :key :value |
			value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ] ].
	details at: #action put: action.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private - schema' }
MCPToolEditRepository >> repositoryEditDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'action'
			   type: 'string'
			   description:
			   'The repository action executed by the tool. Input uses operation to select this action.').
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
MCPToolEditRepository >> repositoryOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repository'
		            type: 'object'
		            description:
		            'Structured metadata for the repository after the edit.'.
	property additionalProperties: true.
	^ property
]

{ #category : 'private - schema' }
MCPToolEditRepository >> repositoryPackageInfoOutputSchemaProperty [

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
MCPToolEditRepository >> repositoryPackagesOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'packages'
		            type: 'array'
		            description:
		            'Packages managed by the repository after the edit.'.
	property items: self repositoryPackageInfoOutputSchemaProperty.
	^ property
]

{ #category : 'testing' }
MCPToolEditRepository >> shouldSaveImageAfterSuccessfulExecutionForResult: aResult [

	| action data structuredContent |
	(aResult isError or: [ aResult structuredContent isNil ]) ifTrue: [
		^ false ].
	structuredContent := aResult structuredContent.
	data := structuredContent at: #data ifAbsent: [ ^ false ].
	action := data
		          at: #action
		          ifAbsent: [
		          ^ self shouldSaveImageAfterSuccessfulExecution ].
	^ (#( 'diff' 'verifyIdentity' ) includes: action) not
]
