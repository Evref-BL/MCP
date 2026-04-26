"
Parsed input for rewrite-methods.

It owns raw tool argument parsing for rewrite rules, preview/apply flags, change-set hash confirmation, and method scope selection.
"
Class {
	#name : 'MCPMethodRewriteRequest',
	#superclass : 'Object',
	#instVars : [
		'rules',
		'apply',
		'expectedChangeSetHash',
		'force',
		'includeSources',
		'scopeQuery'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodRewriteRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request tool: aTool
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> apply [

	^ apply = true
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> expectedChangeSetHash [

	^ expectedChangeSetHash
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> force [

	^ force = true
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> includeSources [

	^ includeSources ~= false
]

{ #category : 'initialization' }
MCPMethodRewriteRequest >> initializeFromRequest: request tool: aTool [

	| ruleObjects |
	ruleObjects := request objectCollectionArgumentNamed: 'rules'.
	ruleObjects ifEmpty: [
		MCPCommandError
			signalErrorCode: #RewriteRulesRequired
			message: 'rewrite-methods requires at least one rewrite rule.'
			details: Dictionary new ].
	rules := OrderedCollection new.
	ruleObjects doWithIndex: [ :eachRule :index |
		rules add: (MCPMethodRewriteRuleSpec
				 fromDictionary: eachRule
				 request: request
				 index: index) ].
	apply := request booleanArgumentNamed: 'apply' default: false.
	force := request booleanArgumentNamed: 'force' default: false.
	includeSources := request
		                  booleanArgumentNamed: 'includeSources'
		                  default: true.
	expectedChangeSetHash := (request hasArgumentNamed:
		                          'expectedChangeSetHash')
		                         ifTrue: [
			                         request
				                         nonNegativeIntegerArgumentNamed:
				                         'expectedChangeSetHash'
				                         default: nil ]
		                         ifFalse: [ nil ].
	scopeQuery := aTool methodScopeQueryFromRequest: request.
	^ self
]

{ #category : 'converting' }
MCPMethodRewriteRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #apply put: self apply.
	self expectedChangeSetHash ifNotNil: [ :hash |
		context at: #expectedChangeSetHash put: hash ].
	context at: #force put: self force.
	context at: #includeSources put: self includeSources.
	context at: #scope put: self scopeQuery asDictionary.
	context at: #rules put: self ruleDictionaries.
	^ context
]

{ #category : 'converting' }
MCPMethodRewriteRequest >> ruleDictionaries [

	^ self rules collect: [ :each | each asDictionary ] as: Array
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> rules [

	^ rules ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodRewriteRequest >> scopeQuery [

	^ scopeQuery
]
