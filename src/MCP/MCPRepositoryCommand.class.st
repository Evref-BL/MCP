"
Abstract base for repository command objects. It owns the shared tool/request state and construction protocol used by repository tools; subclasses implement the repository operation itself.
"
Class {
	#name : 'MCPRepositoryCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryCommand class >> isAbstract [

	^ self = MCPRepositoryCommand
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

{ #category : 'private' }
MCPRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet asArray sort
]
