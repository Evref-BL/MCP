"
Command wrapper for repository_attach. It registers an existing Git checkout as it is, without writing to it, and adds the requested packages to its working copy. It shares repository_create's refusals of a relative location and of a name or location already registered, then refuses a location that does not exist or is no Git root. It answers an MCPRepositoryCreateResult naming the repository's packages, says where HEAD is and where the sources are, and warns when it has no packages, when another repository registers them too, and of a package asked for that neither the image nor the checkout holds.
"
Class {
	#name : 'MCPAttachRepositoryCommand',
	#superclass : 'MCPCreateRepositoryCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - creating' }
MCPAttachRepositoryCommand >> attachRepository [

	^ self registerCheckoutAt: self locationReference during: [ :repository |
			  self request subdirectory ifNotNil: [ :value |
					  self setSubdirectory: value on: repository.
					  "A checkout without .project had no source directory to read its packages from until now."
					  repository workingCopy refreshPackages ] ]
]

{ #category : 'executing' }
MCPAttachRepositoryCommand >> execute [

	| packageWarnings repository result summary |
	^ self
		  executeRepositoryAction: 'attach'
		  work: [
				  self refuseRelativeLocation.
				  self refuseRegisteredNameOrLocation.
				  repository := self attachRepository.
				  self addRequestedPackagesTo: repository.
				  result := MCPRepositoryCreateResult fromRepository: repository.
				  summary := self summaryForAttachedRepository: repository.
				  packageWarnings := self packageWarningsFor: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: summary
				  data: (self tool dataForRepositoryResult: result)
				  warnings: warningMessages , packageWarnings ]
		  failureSummary: [ :error |
				  String streamContents: [ :stream |
					  stream << 'Failed to attach repository ' << self request name << ': ' << (error messageText ifNil: [ error asString ]) ] ]
]

{ #category : 'private - location' }
MCPAttachRepositoryCommand >> locationReference [

	| location |
	location := self request location asFileReference.
	location exists ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationMissing
				message: (String streamContents: [ :stream | stream << self refusalPrefix << location fullName << ' does not exist.' ])
				details: self request requestedContext ].
	(self isGitCheckoutRoot: location) ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationNotGitRoot
				message: (String streamContents: [ :stream |
							 stream << self refusalPrefix << location fullName
							 <<
							 ' is not the root of a Git checkout. repository_create starts a repository there if it holds no file; otherwise run git init there first.' ])
				details: self request requestedContext ].
	^ location
]

{ #category : 'private - results' }
MCPAttachRepositoryCommand >> noPackagesWarningFor: aRepository [

	^ String streamContents: [ :stream |
		  stream << 'Repository ' << aRepository name << ' has no packages; repository_update addPackages adds them.' ]
]

{ #category : 'private - results' }
MCPAttachRepositoryCommand >> packageWarningsFor: aRepository [
	"A package asked for that neither the image nor the checkout holds is likely a name mistyped."

	^ (super packageWarningsFor: aRepository)
	  , (self warningsForPackagesNamed: self request packageNames inNeitherImageNorCheckoutOf: aRepository)
]

{ #category : 'private - results' }
MCPAttachRepositoryCommand >> summaryForAttachedRepository: aRepository [

	^ String streamContents: [ :stream |
			  stream << 'Attached repository ' << aRepository name << ' at ' << aRepository location fullName << ', '
			  << (self headPhraseFor: aRepository) << ', ' << (self sourcesPhraseFor: aRepository) << '.'
			  << (self projectFileNoteFor: aRepository) ]
]
