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

{ #category : 'metadata' }
MCPToolLoadRepository class >> toolName [

	^ 'repository_load'
]

{ #category : 'metadata' }
MCPToolLoadRepository >> buildInputSchema [

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
					   description: 'Repository owner or namespace.').
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'project'
					   description: 'Repository project.').
				  self commitishSchemaProperty.
				  self sourceDirectorySchemaProperty.
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'baseline'
					   description: 'Baseline name without BaselineOf prefix.').
				  self groupsSchemaProperty }
			  , self loadPolicyInputSchemaProperties;
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'metadata' }
MCPToolLoadRepository >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self loadRepositoryDataProperties
		  required: #( 'mode' 'repository' 'load' )
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> checkoutPathSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'checkoutPath'
		   type: 'string'
		   description: 'Local checkout path.')
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
		   description: 'Branch, tag, or commitish.')
		  default: self defaultCommitish;
		  minLength: 1;
		  yourself
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultCommitish [

	^ 'main'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultHostUrl [

	^ 'github'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultSourceDirectory [

	^ '.'
]

{ #category : 'metadata' }
MCPToolLoadRepository >> description [

	^ 'Load a Metacello baseline from a repository source into the image.'
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
		   description: 'Repository host URL or kind.')
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
		   description: 'Registered repository filesystem location.')
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

	^ { (self
		   schemaPropertyNamed: 'repositoryUrl'
		   type: 'string'
		   description: 'Resolved Metacello repository URL.') }
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryNameSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repositoryName'
		   type: 'string'
		   description: 'Registered Iceberg repository name.')
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
		   description: 'Explicit Metacello repository URL.')
		  minLength: 1;
		  yourself
]

{ #category : 'metadata' }
MCPToolLoadRepository >> risk [

	^ 'medium'
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
		   description: 'Repository path containing the baseline.')
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

{ #category : 'metadata' }
MCPToolLoadRepository >> title [

	^ 'Load Repository'
]
