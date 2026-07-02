"
Abstract command support for repository remote-management operations.
"
Class {
	#name : 'MCPRepositoryRemoteCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryRemoteCommand class >> isAbstract [

	^ self = MCPRepositoryRemoteCommand
]

{ #category : 'private - results' }
MCPRepositoryRemoteCommand >> remoteResultForRepository: aRepository [

	^ MCPRepositoryRemoteResult remotes:
		  (MCPGitRepositoryMetadata forRepository: aRepository)
			  remoteDictionaries
]

{ #category : 'private - git' }
MCPRepositoryRemoteCommand >> runRemoteGitArguments: arguments action: actionName in: aRepository [

	self
		runGitArguments: arguments
		in: aRepository
		ifFailed: [ :gitResult |
			self signalGitCommandFailed: gitResult action: actionName ]
]

{ #category : 'private - results' }
MCPRepositoryRemoteCommand >> successResultForRepository: aRepository result: aResult summary: summaryString warnings: warningMessages [

	^ self tool
		  successResultText: summaryString
		  data: (self tool dataForRepositoryResult: aResult)
		  warnings: warningMessages
]
