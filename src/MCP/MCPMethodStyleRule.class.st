"
Abstract base for MCP-owned Renraku rewrite rules that flag local method-shape and collection-style smells.

Subclasses keep the match narrow and name one actionable rewrite family. They are warnings, not mechanical laws. Because this base extends ReNodeRewriteRule, concrete critiques can provide automatic changes through Renraku even when MCP tool output only reports the critique metadata.
"
Class {
	#name : 'MCPMethodStyleRule',
	#superclass : 'ReNodeRewriteRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPMethodStyleRule class >> group [

	^ self designFlawGroup
]

{ #category : 'testing' }
MCPMethodStyleRule class >> isAbstract [

	^ self = MCPMethodStyleRule
]

{ #category : 'accessing' }
MCPMethodStyleRule class >> rationale [

	^ self ruleName
]

{ #category : 'accessing' }
MCPMethodStyleRule class >> ruleName [

	^ 'MCP method style rule'
]

{ #category : 'accessing' }
MCPMethodStyleRule class >> severity [

	^ #warning
]

{ #category : 'accessing' }
MCPMethodStyleRule class >> uniqueIdentifierName [

	^ self name asString
]

{ #category : 'accessing' }
MCPMethodStyleRule >> name [

	^ self class ruleName
]
