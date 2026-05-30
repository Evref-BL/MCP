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
			   'Branch, tag, or commitish to load. Defaults to main.')
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

	^ 'Load a Metacello baseline from a remote Git repository into the image. The tool builds a Metacello repository URL from hostUrl, owner, project, commitish, and sourceDirectory before loading the baseline. hostUrl defaults to github and may identify github, gitlab, or bitbucket; custom hosts can use values such as gitlab://git.example.com. commitish defaults to main, sourceDirectory defaults to ., omitting groups calls Metacello>>load, onWarning defaults to log, and onConflict defaults to useLoaded.'
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
				  self groupsSchemaProperty.
				  self onWarningSchemaProperty.
				  self onConflictSchemaProperty };
		  required: #( 'owner' 'project' 'baseline' );
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
	repositoryUrl := [ loadRequest repositoryUrl ]
		                 on: Error
		                 do: [ :ignored | '' ].
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
MCPToolLoadRepository >> modeOutputSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'mode'
		  description: 'The repository-backed load path used by this tool.'
		  values: #( 'remote' )
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
			   description: 'The requested repository source directory.') }
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repository'
		   type: 'object'
		   description: 'Remote repository coordinates used for the load.')
		  properties: self repositoryDataProperties;
		  required:
			  #( 'repositoryUrl' 'hostUrl' 'owner' 'project' 'commitish'
			     'sourceDirectory' );
		  additionalProperties: false;
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
			   'Repository path containing the baseline. Defaults to . for the repository root.')
		  default: self defaultSourceDirectory;
		  minLength: 1;
		  yourself
]

{ #category : 'private - results' }
MCPToolLoadRepository >> successSummaryForResult: aResult [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Loaded baseline ';
			  nextPutAll: aResult baseline.
		  aResult isRemoteLoad ifTrue: [
			  stream
				  nextPutAll: ' from ';
				  nextPutAll: aResult repositoryUrl ].
		  stream nextPut: $..
		  aResult newPackageNames isEmpty ifFalse: [
			  stream
				  space;
				  nextPutAll: aResult newPackageNames size asString;
				  nextPutAll: ' new packages were detected.' ] ]
]
