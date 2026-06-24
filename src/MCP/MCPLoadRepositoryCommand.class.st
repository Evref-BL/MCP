"
Command for repository_load. It dispatches baseline-only loads to MCPLoadBaselineCommand and remote loads to the same baseline command with repository URL configuration.
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
MCPLoadRepositoryCommand >> baselineCommandClass [

	^ MCPLoadBaselineCommand
]

{ #category : 'private - executing' }
MCPLoadRepositoryCommand >> baselineCommandForRepositoryUrl: repositoryUrl [

	^ self baselineCommandClass
		  tool: self tool
		  request: self request baselineRequest
		  configureMetacello: [ :metacello |
		  metacello repository: repositoryUrl ]
]

{ #category : 'executing' }
MCPLoadRepositoryCommand >> execute [

	| loadResult repositoryUrl |
	repositoryUrl := self request repositoryUrl.
	loadResult := (self baselineCommandForRepositoryUrl: repositoryUrl)
		              execute.
	^ MCPLoadRepositoryResult
		  request: self request
		  repositoryUrl: repositoryUrl
		  loadResult: loadResult
]

{ #category : 'initialization' }
MCPLoadRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'accessing' }
MCPLoadRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPLoadRepositoryCommand >> tool [

	^ tool
]
