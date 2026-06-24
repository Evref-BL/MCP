"
Command wrapper for repository_create. It creates an Iceberg repository through IceRepositoryCreator, registers it in the image, adds requested packages to the working copy, and returns an MCPRepositoryCreateResult.
"
Class {
	#name : 'MCPCreateRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPCreateRepositoryCommand >> addRequestedPackagesTo: aRepository [

	self request packageNames do: [ :each |
		aRepository workingCopy addPackageNamed: each ]
]

{ #category : 'private' }
MCPCreateRepositoryCommand >> createRepository [

	| creator repository |
	creator := IceRepositoryCreator new.
	creator location: self request location asFileReference.
	self request subdirectory ifNotNil: [ :value |
		creator subdirectory: value ].
	repository := creator createNewRepositoryNamed: self request name.
	repository register.
	^ repository
]

{ #category : 'executing' }
MCPCreateRepositoryCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'create'
		  work: [
				  repository := self createRepository.
				  self addRequestedPackagesTo: repository.
				  result := MCPRepositoryCreateResult fromRepository: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Created repository ' , self request name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed create repository ' , self request name , ': '
				  , (error messageText ifNil: [ error asString ]) ]
]
