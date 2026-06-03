"
Compatibility accessor for Iceberg commit-like objects.

Iceberg has exposed commit metadata through slightly different protocols across backends and versions. This class keeps those commit protocol details in one place so repository commands and result DTOs can use explicit MCP-side messages.
"
Class {
	#name : 'MCPIcebergCommitInfo',
	#superclass : 'Object',
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'accessing' }
MCPIcebergCommitInfo class >> commentStringFrom: aCommit [

	aCommit ifNil: [ ^ '' ].
	(self isNoCommit: aCommit) ifTrue: [ ^ '' ].
	^ aCommit comment ifNil: [ '' ]
]

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
