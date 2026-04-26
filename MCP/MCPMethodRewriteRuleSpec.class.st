"
Parsed rewrite rule for rewrite-methods.

It holds one Smalltalk AST rewrite pattern pair and converts it to the NewTools rewriter rule holder used by the command.
"
Class {
	#name : 'MCPMethodRewriteRuleSpec',
	#superclass : 'Object',
	#instVars : [
		'name',
		'lhs',
		'rhs',
		'isForMethod',
		'ruleIndex'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodRewriteRuleSpec class >> fromDictionary: aDictionary request: request index: index [

	^ self new
		  initializeFromDictionary: aDictionary
		  request: request
		  index: index
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> asDictionary [

	^ {
		  (#ruleIndex -> self ruleIndex).
		  (#name -> self name).
		  (#lhs -> self lhs).
		  (#rhs -> self rhs).
		  (#isForMethod -> self isForMethod) } asDictionary
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> asStRewriterRuleHolder [

	^ StRewriterRuleHolder
		  lhs: self lhs
		  rhs: self rhs
		  isForMethod: self isForMethod
]

{ #category : 'converting' }
MCPMethodRewriteRuleSpec >> diagnosticDetails [

	^ {
		  (#ruleIndex -> self ruleIndex).
		  (#ruleName -> self name).
		  (#lhs -> self lhs).
		  (#rhs -> self rhs).
		  (#isForMethod -> self isForMethod) } asDictionary
]

{ #category : 'initialization' }
MCPMethodRewriteRuleSpec >> initializeFromDictionary: aDictionary request: request index: index [

	ruleIndex := index.
	name := request
		        stringArgumentNamed: 'name'
		        in: aDictionary
		        default: 'rule-' , index asString.
	lhs := request stringArgumentNamed: 'lhs' in: aDictionary.
	rhs := request stringArgumentNamed: 'rhs' in: aDictionary.
	isForMethod := request
		               booleanArgumentNamed: 'isForMethod'
		               in: aDictionary
		               default: false.
	self validateAtIndex: index.
	^ self
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> isForMethod [

	^ isForMethod = true
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> lhs [

	^ lhs
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> name [

	^ name
]

{ #category : 'accessing' }
MCPMethodRewriteRuleSpec >> rhs [

	^ rhs
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
	message := 'Rewrite rule ' , self ruleIndex asString
	           , ' has an invalid pattern.'.
	anError messageText ifNotNil: [ :errorMessage |
		message := message , ' ' , errorMessage ].
	MCPCommandError
		signalErrorCode: #RewriteRuleInvalidPattern
		message: message
		details: details
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validateAtIndex: index [

	lhs ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteRuleMissingLhs
			message: 'Rewrite rule ' , index asString , ' is missing lhs.'
			details: self diagnosticDetails ].
	rhs ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteRuleMissingRhs
			message: 'Rewrite rule ' , index asString , ' is missing rhs.'
			details: self diagnosticDetails ]
]

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validatePatterns [

	[ StRewriterRBApplier rewriter: { self asStRewriterRuleHolder } ]
		on: Error
		do: [ :error | self signalInvalidPatternError: error ]
]
