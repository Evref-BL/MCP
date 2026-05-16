"
Command wrapper for edit-repository operation=create. It creates an Iceberg repository through IceRepositoryCreator, registers it in the image, adds requested packages to the working copy, and returns an MCPRepositoryCreateResult.
"
Class {
	#name : 'MCPCreateRepositoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCreateRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

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
	^ self tool
		  executeEditOperation: 'create'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self createRepository.
			  self addRequestedPackagesTo: repository.
			  result := MCPRepositoryCreateResult fromRepository: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Created repository ' , self request name , '.'
				  data: (self tool dataForRepositoryCreateResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to create repository ' , self request name , ': '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPCreateRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPCreateRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCreateRepositoryCommand >> tool [

	^ tool
]
