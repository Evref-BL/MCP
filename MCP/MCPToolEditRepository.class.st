"
MCP tool for mutating Iceberg repositories registered in the image. The public operations are operation=create and operation=update. Creation uses IceRepositoryCreator, registers the repository, and can attach initial packages to the working copy. Updates change repository metadata or package membership in the image only; writing packages to disk belongs to the dedicated repository write tool.
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
	^ super commandForRequest: editRequest
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryCreateResult: aResult [

	| data |
	data := aResult asDictionary copy.
	data at: #operation put: 'create'.
	^ data
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryExportResult: aResult [

	| data |
	data := aResult asDictionary copy.
	data at: #operation put: 'export'.
	^ data
]

{ #category : 'private - results' }
MCPToolEditRepository >> dataForRepositoryUpdateResult: aResult [

	| data |
	data := aResult asDictionary copy.
	data at: #operation put: 'update'.
	^ data
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultDescription [

	^ 'Create, update, or export Iceberg repositories registered in the image. operation=create uses IceRepositoryCreator, registers the repository, and can attach initial packages. operation=update changes repository subdirectory or package membership in the image only: addPackageNames adds packages with workingCopy addPackageNamed:, removePackageNames removes repository membership with IcePackage>>remove without unloading packages, and packageNames replaces membership through those same actions. operation=export writes the image working-copy diff to the repository location by updating the disk working copy and git index; it does not stage or commit.'
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
						   'The high-level repository edit operation. operation=create creates and registers a new Iceberg repository. operation=update changes the selected repository in the image without writing packages to files. operation=export writes the image working-copy diff to files and updates the repository index without staging or committing.'
					   supportedValuesLeadIn: 'Supported values are').
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description:
						   'The repository name to use during operation=create.').
				  (self
					   schemaPropertyNamed: 'repositoryName'
					   type: 'string'
					   description:
						   'Exact registered repository name for operation=update or operation=export. Combine with location when names are ambiguous. Required for export.').
				  (self
					   schemaPropertyNamed: 'location'
					   type: 'string'
					   description:
						   'Filesystem path for operation=create, or an exact registered repository location used to select the repository during operation=update.').
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
		  required: #( 'operation' 'repository' 'packages' 'packageNames' )
]

{ #category : 'defaults' }
MCPToolEditRepository >> defaultTitle [

	^ 'Edit Repository'
]

{ #category : 'private - schema' }
MCPToolEditRepository >> operationBranchSchemas [

	^ (self operationSpecifications collect: [ :each |
		   self
			   inputSchemaBranchForStringDiscriminatorNamed: 'operation'
			   value: (each at: #name)
			   required: (each at: #requiredProperties)
			   requireDiscriminator: true ]) asArray
]

{ #category : 'private - operations' }
MCPToolEditRepository >> operationSpecifications [

	^ {
		  {
			  (#name -> 'create').
			  (#requiredProperties -> #( 'name' 'location' )) } asDictionary.
		  {
			  (#name -> 'update').
			  (#requiredProperties -> #(  )) } asDictionary.
		  {
			  (#name -> 'export').
			  (#requiredProperties -> #( 'repositoryName' )) } asDictionary }
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
	Error signal: self operationValidationErrorMessage
]

{ #category : 'private - schema' }
MCPToolEditRepository >> repositoryEditDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'operation'
			   type: 'string'
			   description: 'The public edit operation that was applied.').
		  self repositoryOutputSchemaProperty.
		  self repositoryPackagesOutputSchemaProperty.
		  (self
			   stringArraySchemaNamed: 'packageNames'
			   description: 'The repository package names after the edit.'
			   itemDescription: 'A package name.').
		  (self
			   stringArraySchemaNamed: 'updateActions'
			   description:
			   'Internal repository update actions applied for operation=update.'
			   itemDescription: 'An update action name.').
		  (self
			   stringArraySchemaNamed: 'addedPackageNames'
			   description:
			   'Package names added to repository membership during operation=update.'
			   itemDescription: 'An added package name.').
		  (self
			   stringArraySchemaNamed: 'removedPackageNames'
			   description:
			   'Package names removed from repository membership during operation=update.'
			   itemDescription: 'A removed package name.').
		  (self
			   stringArraySchemaNamed: 'changedPackageNames'
			   description:
			   'Package names included in the exported working-copy diff.'
			   itemDescription: 'A changed package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPaths'
			   description:
			   'Relative repository paths included in the exported diff when obtainable from Iceberg.'
			   itemDescription: 'A relative repository path.').
		  (self
			   booleanSchemaPropertyNamed: 'didChange'
			   description:
			   'Whether the export diff contained package or path changes.').
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
