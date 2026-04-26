"
Tool that loads a Metacello baseline into the image. It can load an existing baseline already available to Metacello or load from remote Git repository coordinates.
"
Class {
	#name : 'MCPToolLoadRepository',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

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
			   'Branch, tag, or commitish to load for remote loads. Defaults to main when mode is remote.')
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

	^ 'Load a Metacello baseline into the image. When owner/project or mode=remote are provided, the tool builds a Metacello repository URL from hostUrl, owner, project, commitish, and sourceDirectory before loading the baseline. When only baseline options are provided, it loads an existing baseline already available to Metacello without setting a repository. hostUrl defaults to github for remote loads and may identify github, gitlab, or bitbucket; custom hosts can use values such as gitlab://git.example.com. commitish defaults to main, sourceDirectory defaults to ., omitting groups calls Metacello>>load, onWarning defaults to log, and onConflict defaults to useLoaded.'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultHostUrl [

	^ 'github'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #box badgeIconNamed: #add) }
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  self modeSchemaProperty.
				  self hostUrlSchemaProperty.
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'owner'
					   description:
						   'Repository owner or namespace, for example Gabriel-Darbord. Required when mode=remote or other repository coordinates are supplied.').
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'project'
					   description:
						   'Repository project name, for example SmallDoc. Required when mode=remote or other repository coordinates are supplied.').
				  self commitishSchemaProperty.
				  self sourceDirectorySchemaProperty.
				  (self
					   nonEmptyStringSchemaPropertyNamed: 'baseline'
					   description:
						   'Metacello baseline name without the BaselineOf prefix, for example SmallDoc.').
				  self groupsSchemaProperty.
				  self onWarningSchemaProperty.
				  self onConflictSchemaProperty };
		  required: #( 'baseline' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultName [

	^ 'load-repository'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultOnConflict [

	^ 'useLoaded'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultOnWarning [

	^ 'log'
]

{ #category : 'defaults' }
MCPToolLoadRepository >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties:
		  self loadRepositoryDataProperties
		  required: #( 'mode' 'load' )
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
MCPToolLoadRepository >> errorDetailsForError: anError loadRepositoryRequest: loadRepositoryRequest rawRequest: rawRequest [

	| context details |
	details := (anError isKindOf: MCPCommandError)
		           ifTrue: [ anError structuredDetails copy ]
		           ifFalse: [ self errorDetailsFor: anError ].
	context := self
		           requestedContextForErrorFromLoadRepositoryRequest:
		           loadRepositoryRequest
		           rawRequest: rawRequest.
	context keysAndValuesDo: [ :key :value |
		value ifNotNil: [ details at: key ifAbsentPut: [ value ] ] ].
	^ details
]

{ #category : 'private - errors' }
MCPToolLoadRepository >> errorResultForError: anError loadRepositoryRequest: loadRepositoryRequest rawRequest: rawRequest [

	^ self
		  errorResultText: (self
				   failureSummaryForError: anError
				   loadRepositoryRequest: loadRepositoryRequest
				   rawRequest: rawRequest)
		  details: (self
				   errorDetailsForError: anError
				   loadRepositoryRequest: loadRepositoryRequest
				   rawRequest: rawRequest)
]

{ #category : 'executing' }
MCPToolLoadRepository >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :loadRepositoryRequest |
			  | result |
			  result := (self commandForRequest: loadRepositoryRequest) execute.
			  self
				  successResultText: (self successSummaryForResult: result)
				  data: result asDictionary ]
		  onError: [ :error :loadRepositoryRequest |
			  self
				  errorResultForError: error
				  loadRepositoryRequest: loadRepositoryRequest
				  rawRequest: request ]
]

{ #category : 'private - errors' }
MCPToolLoadRepository >> failureSummaryForError: anError loadRepositoryRequest: loadRepositoryRequest rawRequest: rawRequest [

	| baseline message repositoryUrl |
	message := anError messageText
		           ifNil: [ anError asString ]
		           ifNotNil: [ :text | text asString ].
	loadRepositoryRequest ifNil: [
		^ 'Failed to load repository: ' , message ].
	baseline := loadRepositoryRequest baseline ifNil: [ '' ].
	repositoryUrl := loadRepositoryRequest isRemoteLoad
		                 ifTrue: [
			                 [ loadRepositoryRequest repositoryUrl ]
				                 on: Error
				                 do: [ :ignored | '' ] ]
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
MCPToolLoadRepository >> groupsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'groups'
		  description:
		  'Optional Metacello load groups. Omit or pass an empty array to call Metacello>>load.'
		  itemDescription: 'A Metacello group name.'
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> hostUrlSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'hostUrl'
		   type: 'string'
		   description:
			   'Repository host URL or host kind for remote loads. Use github, gitlab, bitbucket, or a Metacello host URL such as gitlab://git.example.com. Defaults to github when mode is remote.')
		  default: self defaultHostUrl;
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> loadBaselineDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'baseline'
			   type: 'string'
			   description: 'The Metacello baseline name requested.').
		  (self
			   stringArraySchemaNamed: 'groups'
			   description: 'Metacello load groups requested.'
			   itemDescription: 'A Metacello group name.').
		  (self
			   schemaPropertyNamed: 'onWarning'
			   type: 'string'
			   description: 'The warning policy used.').
		  (self
			   schemaPropertyNamed: 'onConflict'
			   type: 'string'
			   description: 'The conflict policy used.').
		  (self
			   stringArraySchemaNamed: 'newPackageNames'
			   description:
			   'Packages that appeared in the image after the load and were not present before it started.'
			   itemDescription: 'A package name.').
		  self repositoriesOutputSchemaProperty }
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> loadBaselineOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'load'
		   type: 'object'
		   description:
			   'Baseline load details shared by baseline-only and remote repository loads.')
		  properties: self loadBaselineDataProperties;
		  required:
			  #( 'baseline' 'groups' 'onWarning' 'onConflict' 'newPackageNames'
			     'repositories' );
		  additionalProperties: false;
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
		  description:
		  'The load path used: remote for repository-backed loads, baseline for existing Metacello baselines.'
		  values: #( 'remote' 'baseline' )
		  default: 'baseline'
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> modeSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'mode'
		  description:
		  'Load mode. remote builds and uses a repository URL before loading the baseline; baseline loads an existing Metacello baseline without setting a repository. Omit to infer remote when repository coordinates are supplied and baseline otherwise.'
		  values: #( 'remote' 'baseline' )
		  default: 'baseline'
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> nonEmptyStringSchemaPropertyNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'string'
		   description: propertyDescription)
		  minLength: 1;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> onConflictSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'onConflict'
		  description:
		  'Metacello project conflict handling policy. useLoaded keeps the loaded registration, useIncoming accepts the incoming registration, and pass leaves Metacello default conflict handling.'
		  values: #( 'useLoaded' 'useIncoming' 'pass' )
		  default: self defaultOnConflict
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> onWarningSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'onWarning'
		  description:
		  'Metacello warning handling policy. log records and resumes warnings, resume resumes without logging, and pass leaves Metacello default warning handling.'
		  values: #( 'log' 'resume' 'pass' )
		  default: self defaultOnWarning
]

{ #category : 'private - request' }
MCPToolLoadRepository >> parsedRequestFromToolRequest: request [

	^ MCPLoadRepositoryRequest fromRequest: request tool: self
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoriesOutputSchemaProperty [

	| property |
	property := self
		            schemaPropertyNamed: 'repositories'
		            type: 'array'
		            description:
		            'Iceberg repositories newly registered during the load, when detectable.'.
	property items: self repositoryInfoOutputSchemaProperty.
	^ property
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
MCPToolLoadRepository >> repositoryInfoOutputSchemaProperty [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'Structured metadata for one Iceberg repository newly registered during the load.';
		  additionalProperties: true;
		  yourself
]

{ #category : 'private - schema' }
MCPToolLoadRepository >> repositoryOutputSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'repository'
		   type: 'object'
		   description:
			   'Remote repository coordinates used when mode is remote. Omitted for baseline-only loads.')
		  properties: self repositoryDataProperties;
		  required:
			  #( 'repositoryUrl' 'hostUrl' 'owner' 'project' 'commitish'
			     'sourceDirectory' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - errors' }
MCPToolLoadRepository >> requestedContextForErrorFromLoadRepositoryRequest: loadRepositoryRequest rawRequest: rawRequest [

	loadRepositoryRequest ifNotNil: [
		^ loadRepositoryRequest requestedContext ].
	^ rawRequest asDictionary copy
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
			   'Repository path containing the baseline for remote loads. Defaults to . for the repository root when mode is remote.')
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
