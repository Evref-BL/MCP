"
MCP tool for mutating Iceberg repositories registered in the image. The public operations are create, update, export, diff, and commit. Creation registers a repository and can attach initial packages. Updates change repository metadata or package membership in the image. Export writes image changes to the repository working tree and index without committing. Diff reports pending image changes. Commit creates an Iceberg commit from the current working-copy diff.
"
Class {
	#name : 'MCPToolEditRepository',
	#superclass : 'MCPToolEdit',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolEditRepository >> commandForRequest: editRequest [

	(editRequest isKindOf: MCPRepositoryCreateRequest) ifTrue: [
		^ MCPCreateRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryUpdateRequest) ifTrue: [
		^ MCPUpdateRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryExportRequest) ifTrue: [
		^ MCPExportRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryDiffRequest) ifTrue: [
		^ MCPRepositoryDiffCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryCommitRequest) ifTrue: [
		^ MCPCommitRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryFetchRequest) ifTrue: [
		^ MCPFetchRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryPullRequest) ifTrue: [
		^ MCPPullRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryPushRequest) ifTrue: [
		^ MCPPushRepositoryCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositoryCreateBranchRequest) ifTrue: [
		^ MCPCreateRepositoryBranchCommand tool: self request: editRequest ].
	(editRequest isKindOf: MCPRepositorySwitchBranchRequest) ifTrue: [
		^ MCPSwitchRepositoryBranchCommand tool: self request: editRequest ].
	^ super commandForRequest: editRequest
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

{ #category : 'defaults' }
MCPToolEditRepository >> defaultDescription [

	^ 'Create, update, diff, export, commit, fetch, pull, push, create branches, or switch branches for Iceberg repositories registered in the image. Use repositoryName for existing repositories; add location only to create a repository or disambiguate duplicate names. operation=create registers a repository and can attach packages. operation=update changes image-side repository metadata or package membership without writing packages to files. operation=diff inspects IceRepository>>workingCopyDiff without writing files and should be preferred when you only need to see image-side changes. operation=export is an escape hatch that materializes image changes to disk for Tonel or Git workflows and updates the Iceberg index without staging or committing. operation=commit calls IceRepository>>commitWithMessage:. operation=fetch calls IceRepository>>fetch. operation=pull calls IceRepository>>pull. operation=push calls IceRepository>>push. operation=createBranch calls IceRepository>>createBranch: and switches to the new branch. operation=switchBranch calls IceRepository>>switchToBranchNamed: for an existing branch.'
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #box badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   operationSchemaPropertyWithDescription:
						   'Selects the repository action to execute. Each oneOf branch describes the required fields for its action.'
					   supportedValuesLeadIn: 'Supported values are').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description:
						   'Repository name to use when operation=create registers a new repository.').
				  (self
					   schemaPropertyNamed: 'repositoryName'
					   type: 'string'
					   description:
						   'Registered repository name for operations targeting an existing repository. Combine with location only when names are ambiguous.').
				  (self
					   schemaPropertyNamed: 'location'
					   type: 'string'
					   description:
						   'Filesystem path for operation=create. For existing repositories, combine with repositoryName only to disambiguate duplicate names.').
				  (self
					   schemaPropertyNamed: 'message'
					   type: 'string'
					   description: 'Commit message required by operation=commit.').
				  (self
					   schemaPropertyNamed: 'branchName'
					   type: 'string'
					   description:
						   'Branch name required by operation=createBranch and operation=switchBranch.').
				  (self
					   schemaPropertyNamed: 'subdirectory'
					   type: 'string'
					   description:
						   'Optional source subdirectory for operation=create. During operation=update this sets the repository source subdirectory in the image.').
				  (self
					   stringArraySchemaNamed: 'packageNames'
					   description:
						   'Package names to manage initially during operation=create. During operation=update this replaces the full managed package list by adding and removing repository package membership without unloading packages or writing files.'
					   itemDescription: 'A package name.').
				  (self
					   stringArraySchemaNamed: 'addPackageNames'
					   description:
						   'Package names to add to the repository working copy during operation=update. This does not write packages to files.'
					   itemDescription: 'A package name to add.').
				  (self
					   stringArraySchemaNamed: 'removePackageNames'
					   description:
						   'Package names to remove from repository membership during operation=update using IcePackage>>remove. This does not unload packages from the image.'
					   itemDescription: 'A package name to remove.') };
		  required: #( 'operation' );
		  oneOf: self operationBranchSchemas;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultName [

	^ 'edit-repository'
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self repositoryEditDataProperties
		  required: #( 'action' 'repository' 'packages' 'packageNames' )
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultTitle [

	^ 'Edit Repository'
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
MCPToolEditRepository >> operationBranchSchemas [

	^ (self operationSpecifications collect: [ :each |
		   | branch operationProperty |
		   branch := self
			             inputSchemaBranchForStringDiscriminatorNamed:
			             'operation'
			             value: (each at: #name)
			             required: (each at: #requiredProperties)
			             requireDiscriminator: true.
		   operationProperty := branch properties detect: [ :property |
			                        property name = 'operation' ].
		   operationProperty description: (each at: #description).
		   branch ]) asArray
]

{ #category : 'private - operations' }
MCPToolEditRepository >> operationSpecifications [

	^ {
		  {
			  (#name -> 'create').
			  (#requiredProperties -> #( 'name' 'location' )).
			  (#description
			   ->
			   'Register a new Iceberg repository at location and optionally attach initial packages.') }
			  asDictionary.
		  {
			  (#name -> 'update').
			  (#requiredProperties -> #(  )).
			  (#description
			   ->
			   'Change repository subdirectory or package membership in the image only.') }
			  asDictionary.
		  {
			  (#name -> 'export').
			  (#requiredProperties -> #( 'repositoryName' )).
			  (#description
			   ->
			   'Escape hatch: materialize the image working-copy diff to disk and update the Iceberg index without committing.') }
			  asDictionary.
		  {
			  (#name -> 'diff').
			  (#requiredProperties -> #( 'repositoryName' )).
			  (#description
			   ->
			   'Inspect IceRepository>>workingCopyDiff without writing files; prefer this when checking image-side changes.') }
			  asDictionary.
		  {
			  (#name -> 'commit').
			  (#requiredProperties -> #( 'repositoryName' 'message' )).
			  (#description -> 'Commit the repository with message.') }
			  asDictionary.
		  {
			  (#name -> 'fetch').
			  (#requiredProperties -> #( 'repositoryName' )).
			  (#description -> 'Fetch remote refs through Iceberg.') }
			  asDictionary.
		  {
			  (#name -> 'pull').
			  (#requiredProperties -> #( 'repositoryName' )).
			  (#description -> 'Pull remote changes through Iceberg.') }
			  asDictionary.
		  {
			  (#name -> 'push').
			  (#requiredProperties -> #( 'repositoryName' )).
			  (#description -> 'Push local commits through Iceberg.') }
			  asDictionary.
		  {
			  (#name -> 'createBranch').
			  (#requiredProperties -> #( 'repositoryName' 'branchName' )).
			  (#description
			   -> 'Create branchName from the current head and switch to it.') }
			  asDictionary.
		  {
			  (#name -> 'switchBranch').
			  (#requiredProperties -> #( 'repositoryName' 'branchName' )).
			  (#description -> 'Switch to an existing branchName.') }
			  asDictionary }
]

{ #category : 'private - request' }
MCPToolEditRepository >> parsedRequestFromToolRequest: request [

	| operation |
	operation := self operationFromRequest: request.
	self
		validateRequiredPropertiesForOperation: operation
		inRequest: request.
	operation = 'create' ifTrue: [
		^ MCPRepositoryCreateRequest fromRequest: request tool: self ].
	operation = 'update' ifTrue: [
		^ MCPRepositoryUpdateRequest fromRequest: request tool: self ].
	operation = 'export' ifTrue: [
		^ MCPRepositoryExportRequest fromRequest: request tool: self ].
	operation = 'diff' ifTrue: [
		^ MCPRepositoryDiffRequest fromRequest: request tool: self ].
	operation = 'commit' ifTrue: [
		^ MCPRepositoryCommitRequest fromRequest: request tool: self ].
	operation = 'fetch' ifTrue: [
		^ MCPRepositoryFetchRequest fromRequest: request tool: self ].
	operation = 'pull' ifTrue: [
		^ MCPRepositoryPullRequest fromRequest: request tool: self ].
	operation = 'push' ifTrue: [
		^ MCPRepositoryPushRequest fromRequest: request tool: self ].
	operation = 'createBranch' ifTrue: [
		^ MCPRepositoryCreateBranchRequest fromRequest: request tool: self ].
	operation = 'switchBranch' ifTrue: [
		^ MCPRepositorySwitchBranchRequest fromRequest: request tool: self ].
	Error signal: self operationValidationErrorMessage
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
			   stringArraySchemaNamed: 'modifiedPaths'
			   description:
			   'Relative repository paths included in the working-copy diff when obtainable from Iceberg.'
			   itemDescription: 'A relative repository path.').
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
