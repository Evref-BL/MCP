"
Command for load-repository. It dispatches baseline-only loads to MCPLoadBaselineCommand and remote loads to the same baseline command with repository URL configuration.
"
Class {
	#name : 'MCPLoadRepositoryCommand',
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
MCPLoadRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - executing' }
MCPLoadRepositoryCommand >> baselineCommand [

	^ MCPLoadBaselineCommand
		  tool: self tool
		  request: self request baselineRequest
]

{ #category : 'executing' }
MCPLoadRepositoryCommand >> execute [

	| loadResult repositoryUrl |
	self request isRemoteLoad ifFalse: [
		loadResult := self baselineCommand execute.
		^ MCPLoadRepositoryResult
			  baselineRequest: self request
			  loadResult: loadResult ].
	repositoryUrl := self request repositoryUrl.
	loadResult := (self remoteBaselineCommandForRepositoryUrl:
		               repositoryUrl) execute.
	^ MCPLoadRepositoryResult
		  remoteRequest: self request
		  repositoryUrl: repositoryUrl
		  loadResult: loadResult
]

{ #category : 'initialization' }
MCPLoadRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - executing' }
MCPLoadRepositoryCommand >> remoteBaselineCommandForRepositoryUrl: repositoryUrl [

	^ MCPLoadBaselineCommand
		  tool: self tool
		  request: self request baselineRequest
		  configureMetacello: [ :metacello |
		  metacello repository: repositoryUrl ]
]

{ #category : 'accessing' }
MCPLoadRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPLoadRepositoryCommand >> tool [

	^ tool
]
