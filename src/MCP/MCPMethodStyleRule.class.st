"
Abstract base for MCP-owned Renraku rewrite rules that flag local method-shape and collection-style smells.

Subclasses keep the match narrow and name one actionable rewrite family. They are warnings, not mechanical laws.

Each subclass declares its rewrites as pattern pairs, and this base records them as they are declared so method_rewrite can apply a rule by name. Renraku keeps the same pairs for matching but exposes no way to read them back, so the record is kept here rather than reached for through its instance variables.
"
Class {
	#name : 'MCPMethodStyleRule',
	#superclass : 'ReNodeRewriteRule',
	#instVars : [
		'rewritePatterns'
	],
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPMethodStyleRule >> replace: aPattern with: aReplacement [

	self recordPattern: aPattern replacement: aReplacement forMethod: false.
	^ super replace: aPattern with: aReplacement
]

{ #category : 'accessing' }
MCPMethodStyleRule >> replaceMethod: aPattern with: aReplacement [

	self recordPattern: aPattern replacement: aReplacement forMethod: true.
	^ super replaceMethod: aPattern with: aReplacement
]

{ #category : 'accessing' }
MCPMethodStyleRule >> rewritePatterns [
	"The pattern pairs this rule rewrites with, in the order it declared them."

	^ rewritePatterns ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPMethodStyleRule >> recordPattern: aPattern replacement: aReplacement forMethod: aBoolean [

	rewritePatterns := self rewritePatterns asOrderedCollection.
	rewritePatterns add: {
			(#match -> aPattern).
			(#replacement -> aReplacement).
			(#isForMethod -> aBoolean) } asDictionary
]

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
