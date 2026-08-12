"
Command that updates the URL configured for one repository remote.
"
Class {
	#name : 'MCPUpdateRepositoryRemoteCommand',
	#superclass : 'MCPRepositoryRemoteCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPUpdateRepositoryRemoteCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'remoteUpdate'
		  work: [
				  repository := self request repository.
				  self
					  runRemoteGitArguments: {
							  'remote'.
							  'set-url'.
							  self request remoteName.
							  self request remoteUrl }
					  action: 'remoteUpdate'
					  in: repository.
				  result := self remoteResultForRepository: repository ]
		  successResult: [ :warningMessages |
				  self
					  successResultForRepository: repository
					  result: result
					  summary: 'Updated repository remote for ' , repository name , '.'
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed repository remote update: ' , (error messageText ifNil: [ error asString ]) ]
]
