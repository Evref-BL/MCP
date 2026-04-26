"
Command wrapper for edit-repository operation=commit. It captures the current IceRepository working-copy diff, commits it with IceRepository>>commitWithMessage:, and returns an MCPRepositoryCommitResult.
"
Class {
	#name : 'MCPCommitRepositoryCommand',
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
MCPCommitRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> changedPackageNamesFromDiff: aDiff [

	| names |
	names := [
	         aDiff packages collect: [ :each |
		         self packageNameFromDiffPackageNode: each ] ]
		         on: Error
		         do: [ :ignored | #(  ) ].
	^ self sortedStringsFrom:
		  (names select: [ :each | each notNil and: [ each isEmpty not ] ])
]

{ #category : 'executing' }
MCPCommitRepositoryCommand >> execute [

	| changedPackageNames commit diff repository result |
	^ self tool
		  executeEditOperation: 'commit'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  diff := repository workingCopyDiff.
			  changedPackageNames := self changedPackageNamesFromDiff: diff.
			  commit := self withNonInteractiveAuthorDuring: [
				            repository commitWithMessage: self request message ].
			  result := MCPRepositoryCommitResult
				            repository: repository
				            changedPackageNames: changedPackageNames
				            commit: commit ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Committed repository ' , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryCommitResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to commit repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPCommitRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> packageNameFromDiffPackageNode: aNode [

	| definition |
	definition := aNode definition.
	(definition respondsTo: #packageName) ifFalse: [ ^ nil ].
	^ definition packageName asString
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> request [

	^ request
]

{ #category : 'private' }
MCPCommitRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> tool [

	^ tool
]

{ #category : 'private - execution' }
MCPCommitRepositoryCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ Author fullNamePerSe isEmptyOrNil
		  ifTrue: [ Author useAuthor: 'MCP' during: aBlock ]
		  ifFalse: [ aBlock value ]
]
