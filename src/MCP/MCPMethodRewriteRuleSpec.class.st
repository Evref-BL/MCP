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
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> fromDictionary: aDictionary request: request index: index [

	^ self new initializeFromDictionary: aDictionary request: request index: index
]

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> specsForRuleClassNamed: aName startingAt: anIndex [
	"A rule is a set of pattern pairs, so naming one stands for writing its patterns out. Only MCP's
	own style rules record theirs; Renraku offers no way to read a rule's patterns back."

	| ruleClass patterns |
	ruleClass := MCPImageLookup classNamed: aName.
	(ruleClass inheritsFrom: MCPMethodStyleRule) ifFalse: [
			MCPCommandError
				signalErrorCode: #RewriteRuleClassHasNoPatterns
				message: aName asString , ' does not declare rewrite patterns. Name a subclass of MCPMethodStyleRule.'
				details: { (#ruleClass -> aName) } asDictionary ].
	patterns := ruleClass new rewritePatterns.
	^ patterns withIndexCollect: [ :pattern :offset |
		  self new
			  initializeName: aName
			  match: (pattern at: #match)
			  replacement: (pattern at: #replacement)
			  isForMethod: (pattern at: #isForMethod)
			  index: anIndex + offset - 1 ]
]

{ #category : 'initialization' }
MCPMethodRewriteRuleSpec >> initializeName: aName match: aMatchPattern replacement: aReplacementPattern isForMethod: aBoolean index: anIndex [

	name := aName.
	match := aMatchPattern.
	replacement := aReplacementPattern.
	isForMethod := aBoolean.
	ruleIndex := anIndex
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
