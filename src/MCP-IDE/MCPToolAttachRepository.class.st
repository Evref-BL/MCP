"
Concrete repository_attach tool. It registers an existing Git checkout and optional package membership through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolAttachRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAttachRepository class >> toolName [

	^ 'repository_attach'
]

{ #category : 'private - errors' }
MCPToolAttachRepository >> argumentContextFor: request [

	^ (self creationFor: request) requestedDetails
]

{ #category : 'private - errors' }
MCPToolAttachRepository >> failureSummaryPrefixFor: request [

	^ String streamContents: [ :stream | stream << 'Failed to attach repository ' << (request stringArgumentNamed: 'name') << ': ' ]
]

{ #category : 'private - execution' }
MCPToolAttachRepository >> mutateWith: request [
	"Register an existing Git checkout as it is, and give it packages. A package asked for that neither the image nor the checkout holds is likely a name mistyped, so say so."

	| packageWarnings repository summary |
	^ self
		  executeOperationFor: request
		  work: [
				  repository := (self creationFor: request) attach.
				  summary := self summaryForAttaching: repository.
				  packageWarnings := (self registrationWarningsFor: repository withoutPackages: (String streamContents: [ :stream |
						                       stream << 'Repository ' << repository name
						                       << ' has no packages; repository_update addPackages adds them.' ]))
				                     ,
				                     (self
					                      warningsForPackagesNamed: (request stringCollectionArgumentNamed: 'packages')
					                      inNeitherImageNorCheckoutOf: repository) ]
		  successResult: [ :warnings |
		  self successResultText: summary data: (self dataForPackagesOf: repository) warnings: warnings , packageWarnings ]
]

{ #category : 'private - specs' }
MCPToolAttachRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Attach Repository').
		  (#description -> 'Register an existing Git checkout without creating repository files, and optionally attach packages.').
		  (#action -> 'attach').
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Repository name to register in the image.').
			   (self schemaPropertyNamed: 'location' type: 'string' description: 'Absolute path of the existing Git checkout to register.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description: 'Optional source subdirectory for packages managed by this repository.').
			   (self
				    stringArraySchemaNamed: 'packages'
				    description: 'Package names to manage initially from the attached checkout.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' 'location' )) } asDictionary
]

{ #category : 'private - results' }
MCPToolAttachRepository >> summaryForAttaching: aRepository [

	^ String streamContents: [ :stream |
			  stream << 'Attached repository ' << aRepository name << ' at ' << aRepository location fullName << ', '
			  << (self headPhraseFor: aRepository) << ', ' << (self sourcesPhraseFor: aRepository) << '.'
			  << (self projectFileNoteFor: aRepository) ]
]
