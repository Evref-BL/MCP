"
A commit's id for the repository tools, and whether a commit is Iceberg's no-commit, both safe for nil: the id is empty for no commit at all, as a repository with no commits answers, and for none given.
"
Class {
	#name : 'MCPIcebergCommitInfo',
	#superclass : 'Object',
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'accessing' }
MCPIcebergCommitInfo class >> idStringFrom: aCommit [

	aCommit ifNil: [ ^ '' ].
	(self isNoCommit: aCommit) ifTrue: [ ^ '' ].
	^ aCommit id asString
]

{ #category : 'testing' }
MCPIcebergCommitInfo class >> isNoCommit: aCommit [

	aCommit ifNil: [ ^ false ].
	^ aCommit isNoCommit
]
