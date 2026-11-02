"
A rewrite rule named by its class, as method_rewrite's ruleClasses gives it.

It hands the rewriter the rule's own matchers and replacements rather than writing them out as patterns and parsing them again, so a rule whose replacement is computed by a block applies like any other.
"
Class {
	#name : 'MCPMethodRewriteNamedRuleSpec',
	#superclass : 'Object',
	#instVars : [
		'name',
		'ruleClass',
		'ruleIndex'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodRewriteNamedRuleSpec class >> named: aName index: anIndex [

	^ self new initializeName: aName index: anIndex
]

{ #category : 'rewriting' }
MCPMethodRewriteNamedRuleSpec >> addToRewriter: aRewriter [
	"Each matcher is added with what the rule puts in its place beside it: a tree to copy into the match, or a block to compute the new node. Both answer through rewriten:with:, so a replacement the rule computes needs no pattern form for the tool to write down."

	self rewritesOfRule keysAndValuesDo: [ :matcher :replacement |
			| replaceRule |
			replaceRule := RBBlockReplaceRule new.
			replaceRule searchForTree: matcher replaceWith: [ :node |
					| newNode |
					newNode := replacement rewriten: node with: replaceRule context.
					newNode copyCommentsFrom: node.
					newNode ].
			aRewriter addRule: replaceRule ]
]

{ #category : 'converting' }
MCPMethodRewriteNamedRuleSpec >> asDictionary [

	^ {
		  (#ruleIndex -> self ruleIndex).
		  (#name -> self name) } asDictionary
]

{ #category : 'initialization' }
MCPMethodRewriteNamedRuleSpec >> initializeName: aName index: anIndex [

	name := aName.
	ruleIndex := anIndex.
	ruleClass := MCPImageLookup classNamed: aName.
	(ruleClass inheritsFrom: ReNodeRewriteRule) ifFalse: [
			MCPCommandError
				signalErrorCode: #RewriteRuleClassHasNoPatterns
				message: aName asString , ' is not a rewrite rule. Name a subclass of ReNodeRewriteRule.'
				details: { (#ruleClass -> aName) } asDictionary ]
]

{ #category : 'accessing' }
MCPMethodRewriteNamedRuleSpec >> name [

	^ name
]

{ #category : 'rewriting' }
MCPMethodRewriteNamedRuleSpec >> rewritesOfRule [
	"Renraku keeps a rule's matchers and what to put in their place in an instance variable, and offers no accessor for them."

	^ [ self ruleClass new instVarNamed: 'matches' ]
		  on: Error
		  do: [ :error |
				  MCPCommandError
					  signalErrorCode: #RewriteRuleHasNoReadablePatterns
					  message:
					  (String streamContents: [ :stream | stream << 'Could not read the rewrite patterns of ' << self name asString << '.' ])
					  details: { (#ruleClass -> self name) } asDictionary ]
]

{ #category : 'accessing' }
MCPMethodRewriteNamedRuleSpec >> ruleClass [

	^ ruleClass
]

{ #category : 'accessing' }
MCPMethodRewriteNamedRuleSpec >> ruleIndex [

	^ ruleIndex
]

{ #category : 'rewriting' }
MCPMethodRewriteNamedRuleSpec >> validatePatterns [
	"The rule's patterns are its own and already parsed. There is nothing of the caller's here to refuse."

	self rewritesOfRule
]
