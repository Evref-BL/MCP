"
Parsed rewrite rule for method_rewrite.

It holds one Smalltalk AST rewrite pattern pair and converts it to the NewTools rewriter rule holder used by the command.
"
Class {
	#name : 'MCPMethodRewriteRuleSpec',
	#superclass : 'Object',
	#instVars : [
		'name',
		'match',
		'replacement',
		'isForMethod',
		'ruleIndex'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> fromDictionary: aDictionary request: request index: index [

	^ self new initializeFromDictionary: aDictionary request: request index: index
]

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> rewritePairFor: aMatcher rewriter: aRewriter ruleNamed: aName [
	"A rewriter either carries the tree it rewrites to, or computes it with a block. Only the first
	has a pattern form."

	(aRewriter class allInstVarNames includes: 'tree') ifFalse: [
			MCPCommandError
				signalErrorCode: #RewriteRuleComputesItsReplacement
				message: aName asString , ' computes its replacement instead of writing one, so it has no pattern form.'
				details: { (#ruleClass -> aName) } asDictionary ].
	^ {
		  (#match -> aMatcher formattedCode).
		  (#replacement -> (aRewriter instVarNamed: 'tree') formattedCode).
		  (#isForMethod -> ([ aMatcher isMethod ] on: Error do: [ :error | false ])) } asDictionary
]

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> rewritePairsOf: aRuleClass named: aName [
	"Renraku keeps a rule's pattern pairs in an instance variable and offers no accessor for them.
	The Dictionary holding them does not keep the order they were declared in either, so they are
	sorted, which at least makes one rule always expand the same way."

	| matches pairs |
	matches := [ aRuleClass new instVarNamed: 'matches' ] on: Error do: [ :error | nil ].
	matches ifNil: [
			MCPCommandError
				signalErrorCode: #RewriteRuleHasNoReadablePatterns
				message: 'Could not read the rewrite patterns of ' , aName asString , '.'
				details: { (#ruleClass -> aName) } asDictionary ].
	pairs := OrderedCollection new.
	matches keysAndValuesDo: [ :matcher :rewriter |
		pairs add: (self rewritePairFor: matcher rewriter: rewriter ruleNamed: aName) ].
	^ (pairs asSortedCollection: [ :left :right | (left at: #match) <= (right at: #match) ]) asArray
]

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> specsForRuleClassNamed: aName startingAt: anIndex [
	"A rewrite rule is a set of pattern pairs, so naming one stands for writing its patterns out."

	| ruleClass pairs |
	ruleClass := MCPImageLookup classNamed: aName.
	(ruleClass inheritsFrom: ReNodeRewriteRule) ifFalse: [
			MCPCommandError
				signalErrorCode: #RewriteRuleClassHasNoPatterns
				message: aName asString , ' is not a rewrite rule. Name a subclass of ReNodeRewriteRule.'
				details: { (#ruleClass -> aName) } asDictionary ].
	pairs := self rewritePairsOf: ruleClass named: aName.
	^ pairs withIndexCollect: [ :pair :offset |
		  self new
			  initializeName: aName
			  match: (pair at: #match)
			  replacement: (pair at: #replacement)
			  isForMethod: (pair at: #isForMethod)
			  index: anIndex + offset - 1 ]
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> asDictionary [

	^ {
		  (#ruleIndex -> self ruleIndex).
		  (#name -> self name).
		  (#match -> self match).
		  (#replacement -> self replacement).
		  (#isForMethod -> self isForMethod) } asDictionary
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> asStRewriterRuleHolder [

	^ StRewriterRuleHolder lhs: self match rhs: self replacement isForMethod: self isForMethod
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> diagnosticDetails [

	^ {
		  (#ruleIndex -> self ruleIndex).
		  (#ruleName -> self name).
		  (#match -> self match).
		  (#replacement -> self replacement).
		  (#isForMethod -> self isForMethod) } asDictionary
]

{ #category : 'initialization' }
MCPMethodRewriteRuleSpec >> initializeFromDictionary: aDictionary request: request index: index [

	ruleIndex := index.
	name := request stringArgumentNamed: 'name' in: aDictionary default: 'rule-' , index asString.
	match := (request stringArgumentNamed: 'match' in: aDictionary) withInternalLineEndings.
	replacement := (request stringArgumentNamed: 'replacement' in: aDictionary) withInternalLineEndings.
	isForMethod := request booleanArgumentNamed: 'isForMethod' in: aDictionary default: false.
	self validateAtIndex: index.
	^ self
]

{ #category : 'initialization' }
MCPMethodRewriteRuleSpec >> initializeName: aName match: aMatchPattern replacement: aReplacementPattern isForMethod: aBoolean index: anIndex [

	name := aName.
	match := aMatchPattern.
	replacement := aReplacementPattern.
	isForMethod := aBoolean.
	ruleIndex := anIndex
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> isForMethod [

	^ isForMethod = true
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> match [

	^ match
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> name [

	^ name
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> replacement [

	^ replacement
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> ruleIndex [

	^ ruleIndex
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> signalInvalidPatternError: anError [

	| details message |
	details := self diagnosticDetails.
	details at: #backendErrorClass put: anError class name asString.
	details at: #backendMessage put: anError messageText.
	message := 'Rewrite rule ' , self ruleIndex asString , ' has an invalid pattern.'.
	anError messageText ifNotNil: [ :errorMessage | message := message , ' ' , errorMessage ].
	MCPCommandError signalErrorCode: #RewriteRuleInvalidPattern message: message details: details
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validateAtIndex: index [

	match ifNil: [
			MCPCommandError
				signalErrorCode: #RewriteRuleMissingLhs
				message: 'Rewrite rule ' , index asString , ' is missing match.'
				details: self diagnosticDetails ].
	replacement ifNil: [
			MCPCommandError
				signalErrorCode: #RewriteRuleMissingRhs
				message: 'Rewrite rule ' , index asString , ' is missing replacement.'
				details: self diagnosticDetails ]
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validatePatterns [

	[ StRewriterRBApplier rewriter: { self asStRewriterRuleHolder } ]
		on: Error
		do: [ :error | self signalInvalidPatternError: error ]
]
