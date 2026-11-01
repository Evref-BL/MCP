"
Abstract base for MCP-owned Renraku rewrite rules that flag local method-shape and collection-style smells.

Subclasses keep the match narrow and name one actionable rewrite family. They are warnings, not mechanical laws.

Each subclass declares its rewrites as pattern pairs, which is what makes them applicable: method_rewrite reads the pairs of any rewrite rule and can be given one by name.

A pattern that matches more than its rule is about says so in a pattern block on the metavariable, calling the tests on my class side: canSend:to: keeps a rewrite off a receiver the source shows would not understand it, and isValueUnused: keeps one that answers something else to where nothing reads the answer. A condition kept anywhere else would reach the critique and not method_rewrite.
"
Class {
	#name : 'MCPMethodStyleRule',
	#superclass : 'ReNodeRewriteRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'testing' }
MCPMethodStyleRule class >> canSend: aSelector to: aNode [
	"Pattern blocks call this to keep a rewrite off a receiver that would not understand what it sends instead. Only a receiver whose class the source says is ruled out; any other may understand it."

	^ (self classKnownFor: aNode) ifNil: [ true ] ifNotNil: [ :class | class canUnderstand: aSelector ]
]

{ #category : 'testing' }
MCPMethodStyleRule class >> classKnownFor: aNode [
	"The class the value of aNode is an instance of, where the source alone says it, or nil."

	aNode isLiteralNode ifTrue: [ ^ aNode value class ].
	aNode isDynamicArray ifTrue: [ ^ Array ].
	aNode isSelfVariable ifTrue: [ ^ aNode methodNode methodClass ].
	aNode isSuperVariable ifTrue: [ ^ aNode methodNode methodClass superclass ].
	(self isClassReference: aNode) ifTrue: [ ^ aNode binding value class ].
	^ nil
]

{ #category : 'accessing' }
MCPMethodStyleRule class >> group [

	^ #'Design Flaws'
]

{ #category : 'testing' }
MCPMethodStyleRule class >> isAbstract [

	^ self = MCPMethodStyleRule
]

{ #category : 'testing' }
MCPMethodStyleRule class >> isClassReference: aNode [

	^ aNode isVariable and: [ aNode isGlobalVariable and: [ aNode binding value isClassOrTrait ] ]
]

{ #category : 'testing' }
MCPMethodStyleRule class >> isStatement: aNode [

	^ aNode parent isSequence
]

{ #category : 'testing' }
MCPMethodStyleRule class >> isValueUnused: aNode [
	"Pattern blocks call this before a rewrite that answers something else. A statement's value is thrown away unless it ends a block, whose value is that statement's, and so is a cascaded message's unless it ends the cascade."

	| parent |
	parent := aNode parent.
	parent isCascade ifTrue: [ ^ parent messages last ~~ aNode or: [ self isValueUnused: parent ] ].
	parent isSequence ifFalse: [ ^ false ].
	^ parent parent isMethod or: [ parent statements last ~~ aNode ]
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
