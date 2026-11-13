"
A rewrite rule the caller wrote out, as method_rewrite's rules gives it.

It holds one Smalltalk AST rewrite pattern pair and adds it to the rewriter the command applies. A rule named by its class instead is an MCPMethodRewriteNamedRuleSpec.
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

{ #category : 'rewriting' }
MCPMethodRewriteRuleSpec >> addToRewriter: aRewriter [

	self isForMethod
		ifTrue: [ aRewriter replaceMethod: self match with: self replacement ]
		ifFalse: [ aRewriter replace: self match with: self replacement ]
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
	match := request stringArgumentNamed: 'match' in: aDictionary.
	replacement := request stringArgumentNamed: 'replacement' in: aDictionary.
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
	message := String streamContents: [ :stream | stream << 'Rewrite rule ' << self ruleIndex asString << ' has an invalid pattern.' ].
	anError messageText ifNotNil: [ :errorMessage |
		message := String streamContents: [ :stream | stream << message << ' ' << errorMessage ] ].
	MCPCommandError signalErrorCode: #RewriteRuleInvalidPattern message: message details: details
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validateAtIndex: index [

	match ifNil: [
			MCPCommandError
				signalErrorCode: #RewriteRuleMissingLhs
				message: (String streamContents: [ :stream | stream << 'Rewrite rule ' << index asString << ' is missing match.' ])
				details: self diagnosticDetails ].
	replacement ifNil: [
			MCPCommandError
				signalErrorCode: #RewriteRuleMissingRhs
				message: (String streamContents: [ :stream | stream << 'Rewrite rule ' << index asString << ' is missing replacement.' ])
				details: self diagnosticDetails ]
]
