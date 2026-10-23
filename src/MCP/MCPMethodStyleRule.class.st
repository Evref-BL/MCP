"
Abstract base for MCP-owned Renraku rewrite rules that flag local method-shape and collection-style smells.

Subclasses keep the match narrow and name one actionable rewrite family. They are warnings, not mechanical laws.

Each subclass declares its rewrites as pattern pairs, which is what makes them applicable: method_rewrite reads the pairs of any rewrite rule and can be given one by name.
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

	^ #'Design Flaws'
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
