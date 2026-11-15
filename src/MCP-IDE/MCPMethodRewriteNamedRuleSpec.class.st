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

{ #category : 'testing' }
MCPMethodRewriteNamedRuleSpec class >> canApplyRuleClass: aClass [
	"Whether method_rewrite can apply the rule named by aClass: it is a rewrite rule, and its matchers read and are not empty. A critique names its rule for method_rewrite only then, since only then does the caller have something to do with it."

	(self isRewriteRuleClass: aClass) ifFalse: [ ^ false ].
	^ [ (self rewritesOfRuleClass: aClass) isEmptyOrNil not ]
		  on: Error
		  do: [ :error | false ]
]

{ #category : 'testing' }
MCPMethodRewriteNamedRuleSpec class >> isRewriteRuleClass: aClass [
	"Only a rewrite rule carries matchers and what to put in their place."

	^ aClass isBehavior and: [ aClass inheritsFrom: ReNodeRewriteRule ]
]

{ #category : 'instance creation' }
MCPMethodRewriteNamedRuleSpec class >> named: aName index: anIndex [

	^ self new initializeName: aName index: anIndex
]

{ #category : 'accessing' }
MCPMethodRewriteNamedRuleSpec class >> rewritesOfRuleClass: aRuleClass [
	"Renraku keeps a rule's matchers and what to put in their place in an instance variable, and offers no accessor for them."

	^ aRuleClass new instVarNamed: 'matches'
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
	ruleClass := MCPImageLookup classNamed: aName role: #rewriteRule details: #(  )
]

{ #category : 'accessing' }
MCPMethodRewriteNamedRuleSpec >> name [

	^ name
]

{ #category : 'rewriting' }
MCPMethodRewriteNamedRuleSpec >> rewritesOfRule [

	^ [ self class rewritesOfRuleClass: self ruleClass ]
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
