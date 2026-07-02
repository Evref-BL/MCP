"
Result containing the current compact remote list for a repository after a remote-management operation.
"
Class {
	#name : 'MCPRepositoryRemoteResult',
	#superclass : 'MCPResult',
	#instVars : [
		'remotes'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryRemoteResult class >> remotes: remoteDictionaries [

	^ self new initializeRemotes: remoteDictionaries
]

{ #category : 'converting' }
MCPRepositoryRemoteResult >> asDictionary [

	^ { (#remotes -> self remotes) } asDictionary
]

{ #category : 'initialization' }
MCPRepositoryRemoteResult >> initializeRemotes: remoteDictionaries [

	remotes := remoteDictionaries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryRemoteResult >> remotes [

	^ remotes
]

{ #category : 'accessing' }
MCPRepositoryRemoteResult >> remotes: remoteDictionaries [

	remotes := remoteDictionaries
]
