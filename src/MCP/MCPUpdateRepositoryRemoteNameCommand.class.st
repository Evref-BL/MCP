"
Command that renames one repository remote.
"
Class {
	#name : 'MCPUpdateRepositoryRemoteNameCommand',
	#superclass : 'MCPRepositoryRemoteCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPUpdateRepositoryRemoteNameCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'remoteNameUpdate'
		  work: [
				  repository := self request repository.
				  self
					  runRemoteGitArguments: {
							  'remote'.
							  'rename'.
							  self request remoteName.
							  self request newRemoteName }
					  action: 'remoteNameUpdate'
					  in: repository.
				  result := self remoteResultForRepository: repository ]
		  successResult: [ :warningMessages |
				  self
					  successResultForRepository: repository
					  result: result
					  summary:
					  'Renamed repository remote for ' , repository name , '.'
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed repository remote name update: '
				  , (error messageText ifNil: [ error asString ]) ]
]
