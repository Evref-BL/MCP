"
Command that removes one remote from a registered repository.
"
Class {
	#name : 'MCPRemoveRepositoryRemoteCommand',
	#superclass : 'MCPRepositoryRemoteCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPRemoveRepositoryRemoteCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'remoteRemove'
		  work: [
				  repository := self request repository.
				  self
					  runRemoteGitArguments: {
							  'remote'.
							  'remove'.
							  self request remoteName }
					  action: 'remoteRemove'
					  in: repository.
				  result := self remoteResultForRepository: repository ]
		  successResult: [ :warningMessages |
				  self
					  successResultForRepository: repository
					  result: result
					  summary:
					  'Removed repository remote for ' , repository name , '.'
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed repository remote remove: '
				  , (error messageText ifNil: [ error asString ]) ]
]
