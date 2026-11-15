"
Concrete repository_create tool. It starts a Git repository with no history at a location that does not exist yet or holds no file, registers it and gives it packages from the image, through MCPToolRepositoryOperation. An existing checkout is registered with repository_attach instead.
"
Class {
	#name : 'MCPToolCreateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCreateRepository class >> toolName [

	^ 'repository_create'
]

{ #category : 'private - errors' }
MCPToolCreateRepository >> argumentContextFor: request [

	^ (self creationFor: request) requestedDetails
]

{ #category : 'private - errors' }
MCPToolCreateRepository >> failureSummaryFor: anError request: request [

	^ String streamContents: [ :stream |
			  stream << 'Failed to create repository ' << (request stringArgumentNamed: 'name') << ': '
			  << (anError messageText ifNil: [ anError asString ]) ]
]

{ #category : 'private - execution' }
MCPToolCreateRepository >> mutateWith: request [
	"Start a repository with no history, register it and give it packages from the image."

	| packageWarnings repository summary |
	^ self
		  executeOperationFor: request
		  work: [
				  | creation |
				  creation := self creationFor: request.
				  repository := creation execute.
				  summary := self summaryForCreating: repository in: creation locationState.
				  packageWarnings := self registrationWarningsFor: repository withoutPackages: (String streamContents: [ :stream |
						                      stream << 'Repository ' << repository name
						                      << ' has no packages yet; repository_update addPackages adds them.' ]) ]
		  successResult: [ :warnings |
		  self successResultText: summary data: (self dataForPackagesOf: repository) warnings: warnings , packageWarnings ]
]

{ #category : 'private - specs' }
MCPToolCreateRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Create Repository').
		  (#description
		   ->
		   'Start a Git repository with no history at a location that does not exist yet or holds no file, register it, and give it packages from the image. An existing checkout is registered with repository_attach. Without a location, the repository goes in Iceberg''s own directory of repositories, under its name.').
		  (#action -> 'create').
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Repository name for the new repository.').
			   (self
				    schemaPropertyNamed: 'location'
				    type: 'string'
				    description:
				    'Absolute path of the new repository: a directory that does not exist yet, one that holds no file, or a Git repository with no commit.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description: 'Directory inside the repository for the package sources, such as src. Defaults to its root.').
			   (self
				    stringArraySchemaNamed: 'packages'
				    description: 'Packages of the image the repository holds.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' )) } asDictionary
]

{ #category : 'private - results' }
MCPToolCreateRepository >> summaryForCreating: aRepository in: aLocationState [

	^ String streamContents: [ :stream |
			  stream << 'Created repository ' << aRepository name << (aLocationState = #emptyCheckout
				   ifTrue: [ ' in the empty Git repository at ' ]
				   ifFalse: [ ' at ' ]) << aRepository location fullName << ', ' << (self sourcesPhraseFor: aRepository)
			  << '; repository_export writes its packages there.' ]
]
