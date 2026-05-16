"
Command wrapper for edit-repository operation=update. It applies repository package membership and metadata changes from a parsed MCPRepositoryUpdateRequest without writing the repository to disk.
"
Class {
	#name : 'MCPUpdateRepositoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request',
		'addedPackageNames',
		'removedPackageNames'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - packages' }
MCPUpdateRepositoryCommand >> addPackageNamed: packageName to: aRepository [

	((self currentPackageNamesIn: aRepository) includes: packageName)
		ifTrue: [ ^ self ].
	aRepository workingCopy addPackageNamed: packageName.
	addedPackageNames add: packageName
]

{ #category : 'private - packages' }
MCPUpdateRepositoryCommand >> addPackagesTo: aRepository [

	self request addPackageNames do: [ :each |
		self addPackageNamed: each to: aRepository ]
]

{ #category : 'accessing' }
MCPUpdateRepositoryCommand >> addedPackageNames [

	^ addedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPUpdateRepositoryCommand >> currentPackageNamesIn: aRepository [

	^ self normalizedPackageNames: aRepository workingCopy packageNames
]

{ #category : 'executing' }
MCPUpdateRepositoryCommand >> execute [

	| repository result |
	^ self tool
		  executeEditOperation: 'update'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  self request hasUpdates ifFalse: [ self signalNoUpdateRequested ].
			  repository := self request repository.
			  (self request hasSuppliedPropertyNamed: 'subdirectory') ifTrue: [
				  self setSubdirectoryOn: repository ].
			  (self request hasSuppliedPropertyNamed: 'packageNames') ifTrue: [
				  self replacePackagesIn: repository ].
			  self addPackagesTo: repository.
			  self removePackagesFrom: repository.
			  result := MCPRepositoryUpdateResult
				            repository: repository
				            updateActions:
				            self request requestedRepositoryUpdateActions
				            addedPackageNames: self sortedAddedPackageNames
				            removedPackageNames: self sortedRemovedPackageNames ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Updated repository ' , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryUpdateResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to update repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPUpdateRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	addedPackageNames := OrderedCollection new.
	removedPackageNames := OrderedCollection new.
	^ self
]

{ #category : 'private' }
MCPUpdateRepositoryCommand >> normalizedPackageNames: packageNames [

	^ (packageNames collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'private - packages' }
MCPUpdateRepositoryCommand >> removePackageNamed: packageName from: aRepository [

	| package |
	package := aRepository workingCopy
		           packageNamed: packageName
		           ifAbsent: [ ^ self ].
	package remove.
	removedPackageNames add: packageName
]

{ #category : 'private - packages' }
MCPUpdateRepositoryCommand >> removePackagesFrom: aRepository [

	self request removePackageNames do: [ :each |
		self removePackageNamed: each from: aRepository ]
]

{ #category : 'accessing' }
MCPUpdateRepositoryCommand >> removedPackageNames [

	^ removedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'private - packages' }
MCPUpdateRepositoryCommand >> replacePackagesIn: aRepository [

	| currentPackages desiredPackages |
	desiredPackages := self normalizedPackageNames:
		                   self request packageNames.
	currentPackages := self currentPackageNamesIn: aRepository.
	(currentPackages reject: [ :each | desiredPackages includes: each ])
		do: [ :each | self removePackageNamed: each from: aRepository ].
	(desiredPackages reject: [ :each | currentPackages includes: each ])
		do: [ :each | self addPackageNamed: each to: aRepository ]
]

{ #category : 'accessing' }
MCPUpdateRepositoryCommand >> request [

	^ request
]

{ #category : 'private - metadata' }
MCPUpdateRepositoryCommand >> setSubdirectoryOn: aRepository [

	(aRepository respondsTo: #subdirectory:) ifFalse: [
		MCPCommandError
			signalErrorCode: #RepositorySubdirectoryUnsupported
			message:
			'The selected Iceberg repository cannot store a subdirectory.'
			details: self request requestedContext ].
	aRepository subdirectory: (self request subdirectory ifNil: [ '' ])
]

{ #category : 'private - signaling' }
MCPUpdateRepositoryCommand >> signalNoUpdateRequested [

	MCPCommandError
		signalErrorCode: #NoRepositoryUpdateRequested
		message:
		'operation=update requires subdirectory, packageNames, addPackageNames, or removePackageNames.'
		details: self request requestedContext
]

{ #category : 'private' }
MCPUpdateRepositoryCommand >> sortedAddedPackageNames [

	^ self normalizedPackageNames: self addedPackageNames
]

{ #category : 'private' }
MCPUpdateRepositoryCommand >> sortedRemovedPackageNames [

	^ self normalizedPackageNames: self removedPackageNames
]

{ #category : 'accessing' }
MCPUpdateRepositoryCommand >> tool [

	^ tool
]
