"
Command that updates the URL configured for one repository remote.
"
Class {
	#name : 'MCPUpdateRepositoryRemoteUrlCommand',
	#superclass : 'MCPRepositoryRemoteCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPUpdateRepositoryRemoteUrlCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'remoteUrlUpdate'
		  work: [
				  repository := self request repository.
				  self
					  runRemoteGitArguments: {
							  'remote'.
							  'set-url'.
							  self request remoteName.
							  self request remoteUrl }
					  action: 'remoteUrlUpdate'
					  in: repository.
				  result := self remoteResultForRepository: repository ]
		  successResult: [ :warningMessages |
				  self
					  successResultForRepository: repository
					  result: result
					  summary:
					  'Updated repository remote URL for ' , repository name , '.'
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed repository remote URL update: '
				  , (error messageText ifNil: [ error asString ]) ]
]
