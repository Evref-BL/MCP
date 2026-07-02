"
Command that adds one remote to a registered repository.
"
Class {
	#name : 'MCPAddRepositoryRemoteCommand',
	#superclass : 'MCPRepositoryRemoteCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPAddRepositoryRemoteCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'remoteAdd'
		  work: [
				  repository := self request repository.
				  self
					  runRemoteGitArguments: {
							  'remote'.
							  'add'.
							  self request remoteName.
							  self request remoteUrl }
					  action: 'remoteAdd'
					  in: repository.
				  result := self remoteResultForRepository: repository ]
		  successResult: [ :warningMessages |
				  self
					  successResultForRepository: repository
					  result: result
					  summary: 'Added repository remote for ' , repository name , '.'
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed repository remote add: '
				  , (error messageText ifNil: [ error asString ]) ]
]
