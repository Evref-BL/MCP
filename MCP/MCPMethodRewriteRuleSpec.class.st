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
		'isForMethod'
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

{ #category : 'initialization' }
MCPMethodRewriteRuleSpec >> initializeFromDictionary: aDictionary request: request index: index [

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

{ #category : 'validating' }
MCPMethodRewriteRuleSpec >> validateAtIndex: index [

	lhs ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteRuleMissingLhs
			message: 'Rewrite rule ' , index asString , ' is missing lhs.'
			details: { (#ruleIndex -> index) } asDictionary ].
	rhs ifNil: [
		MCPCommandError
			signalErrorCode: #RewriteRuleMissingRhs
			message: 'Rewrite rule ' , index asString , ' is missing rhs.'
			details: { (#ruleIndex -> index) } asDictionary ]
]
