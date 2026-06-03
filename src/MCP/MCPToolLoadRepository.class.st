"
Tool that loads a Metacello baseline from remote Git repository coordinates into the image.
"
Class {
	#name : 'MCPToolLoadRepository',
	#superclass : 'MCPToolLoadMetacello',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolLoadRepository class >> toolName [

	^ 'repository_load'
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> checkoutPathSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'checkoutPath'
		   type: 'string'
		   description:
			   'Filesystem path of a local checkout. Combined with sourceDirectory to build a tonel:// repository URL.')
		  minLength: 1;
		  yourself
]

{ #category : 'private - execution' }
MCPToolLoadRepository >> commandForRequest: loadRepositoryRequest [

	^ MCPLoadRepositoryCommand tool: self request: loadRepositoryRequest
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> commitishSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'commitish'
		   type: 'string'
		   description:
			   'Branch, tag, or commitish to load. Defaults to main. Slashes are escaped when building Metacello remote URLs.')
		  default: self defaultCommitish;
		  minLength: 1;
		  yourself
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultCommitish [

	^ 'main'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultDescription [

	^ 'Load a Metacello baseline from a repository source into the image. Use owner/project for hosted remote repositories, repositoryUrl for an explicit Metacello URL such as tonel://, checkoutPath for a local checkout, or repositoryName/location for a registered Iceberg repository. sourceDirectory defaults to . where applicable. Supports Metacello warning, conflict, upgrade, downgrade, and lock policies.'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultHostUrl [

	^ 'github'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  self repositoryUrlSchemaProperty.
				  self checkoutPathSchemaProperty.
				  self repositoryNameSchemaProperty.
				  self locationSchemaProperty.
				  self hostUrlSchemaProperty.
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'owner'
					   description:
						   'Repository owner or namespace, for example Gabriel-Darbord.').
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'project'
					   description: 'Repository project name, for example SmallDoc.').
				  self commitishSchemaProperty.
				  self sourceDirectorySchemaProperty.
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'baseline'
					   description:
						   'Metacello baseline name without the BaselineOf prefix, for example SmallDoc.').
				  self groupsSchemaProperty }
			  , self loadPolicyInputSchemaProperties;
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self loadRepositoryDataProperties
		  required: #( 'mode' 'repository' 'load' )
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultSourceDirectory [

	^ '.'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultTitle [

	^ 'Load Repository'
]

{ #category : 'private - errors' }
MCPToolLoadRepository >> failureSummaryForError: anError loadRequest: loadRequest rawRequest: rawRequest [

	| baseline message repositoryUrl |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
	loadRequest ifNil: [ ^ 'Failed to load repository: ' , message ].
	baseline := loadRequest baseline ifNil: [ '' ].
	repositoryUrl := loadRequest canResolveRepositoryUrl
		                 ifTrue: [ loadRequest repositoryUrl ]
		                 ifFalse: [ '' ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: 'Failed to load baseline'.
			  baseline isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: baseline ].
			  repositoryUrl isEmpty ifFalse: [
					  stream
						  nextPutAll: ' from ';
						  nextPutAll: repositoryUrl ].
			  stream
				  nextPutAll: ': ';
				  nextPutAll: message ]
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> hostUrlSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'hostUrl'
		   type: 'string'
		   description:
			   'Repository host URL or host kind. Use github, gitlab, bitbucket, or a Metacello host URL such as gitlab://git.example.com. Defaults to github.')
		  default: self defaultHostUrl;
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> loadRepositoryDataProperties [

	^ {
		  self modeOutputSchemaProperty.
		  self repositoryOutputSchemaProperty.
		  self loadBaselineOutputSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> locationSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'location'
		   type: 'string'
		   description:
			   'Filesystem location of an Iceberg repository already registered in the image. May be combined with repositoryName to disambiguate.')
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> modeOutputSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'mode'
		  description: 'The repository source mode used by this tool.'
		  values: #( 'remote' 'url' 'local' 'iceberg' )
		  default: 'remote'
]

{ #category : 'private - request' }
MCPToolLoadRepository >> parsedRequestFromToolRequest: request [

	^ MCPLoadRepositoryRequest fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'repositoryUrl'
			   type: 'string'
			   description: 'The Metacello repository URL used for the load.').
		  (self
			   schemaPropertyNamed: 'hostUrl'
			   type: 'string'
			   description: 'The requested repository host URL or host kind.').
		  (self
			   schemaPropertyNamed: 'owner'
			   type: 'string'
			   description: 'The requested repository owner or namespace.').
		  (self
			   schemaPropertyNamed: 'project'
			   type: 'string'
			   description: 'The requested repository project/name segment.').
		  (self
			   schemaPropertyNamed: 'commitish'
			   type: 'string'
			   description: 'The requested branch, tag, or commitish.').
		  (self
			   schemaPropertyNamed: 'sourceDirectory'
			   type: 'string'
			   description: 'The requested repository source directory.').
		  (self
			   schemaPropertyNamed: 'checkoutPath'
			   type: 'string'
			   description: 'The local checkout path used for local mode.').
		  (self
			   schemaPropertyNamed: 'repositoryName'
			   type: 'string'
			   description:
			   'The registered Iceberg repository name used for iceberg mode.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description:
			   'The registered Iceberg repository location used for iceberg mode.') }
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryNameSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repositoryName'
		   type: 'string'
		   description:
			   'Name of an Iceberg repository already registered in the image. Combined with its location and sourceDirectory/subdirectory to build a local tonel:// URL.')
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repository'
		   type: 'object'
		   description: 'Repository source used for the load.')
		  properties: self repositoryDataProperties;
		  required: #( 'repositoryUrl' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryUrlSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repositoryUrl'
		   type: 'string'
		   description:
			   'Explicit Metacello repository URL to load from, for example tonel:///path/to/checkout/src.')
		  minLength: 1;
		  yourself
]

{ #category : 'testing' }
MCPToolLoadRepository >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> sourceDirectorySchemaProperty [

	^ (self
		   schemaPropertyNamed: 'sourceDirectory'
		   type: 'string'
		   description:
			   'Repository path containing the baseline. Defaults to . for remote/local sources and to the registered Iceberg subdirectory for iceberg mode.')
		  default: self defaultSourceDirectory;
		  minLength: 1;
		  yourself
]

{ #category : 'private - results' }
MCPToolLoadRepository >> successSummaryForResult: aResult [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Loaded baseline ';
				  nextPutAll: aResult baseline;
				  nextPutAll: ' from ';
				  nextPutAll: aResult repositoryUrl;
				  nextPut: $..
			  aResult newPackageNames isEmpty ifFalse: [
					  stream
						  space;
						  nextPutAll: aResult newPackageNames size asString;
						  nextPutAll: ' new packages were detected.' ] ]
]
