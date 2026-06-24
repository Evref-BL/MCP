"
Abstract base for repository command objects. It owns the shared tool/request state and construction protocol used by repository tools; subclasses implement the repository operation itself.
"
Class {
	#name : 'MCPRepositoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryCommand class >> isAbstract [

	^ self = MCPRepositoryCommand
]

{ #category : 'instance creation' }
MCPRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

{ #category : 'private - execution' }
MCPRepositoryCommand >> executeRepositoryAction: actionName work: workBlock successResult: successBlock failureSummary: failureBlock [

	^ self tool
		  executeMutationAction: actionName
		  force: false
		  requestedContext: self request requestedContext
		  work: workBlock
		  successResult: successBlock
		  failureSummary: failureBlock
]

{ #category : 'initialization' }
MCPRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'accessing' }
MCPRepositoryCommand >> request [

	^ request
]

{ #category : 'private' }
MCPRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet asArray sort
]

{ #category : 'accessing' }
MCPRepositoryCommand >> tool [

	^ tool
]
