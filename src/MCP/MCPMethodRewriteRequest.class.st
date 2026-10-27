"
Parsed input for method_rewrite.

It owns raw tool argument parsing for rewrite rules, the rule classes that stand for sets of them, the preview flag, and method scope selection.
"
Class {
	#name : 'MCPMethodRewriteRequest',
	#superclass : 'Object',
	#instVars : [
		'rules',
		'apply',
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
MCPMethodRewriteRequest >> includeSources [
	"A preview exists to show what would change; an apply has already changed it."

	^ self apply not
]

{ #category : 'initialization' }
MCPMethodRewriteRequest >> initializeFromRequest: request tool: aTool [

	| ruleObjects ruleClassNames |
	ruleObjects := request objectCollectionArgumentNamed: 'rules'.
	ruleClassNames := request stringCollectionArgumentNamed: 'ruleClasses'.
	(ruleObjects isEmpty and: [ ruleClassNames isEmpty ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #RewriteRulesRequired
				message: 'method_rewrite requires rules, ruleClasses, or both.'
				details: Dictionary new ].
	rules := OrderedCollection new.
	ruleObjects doWithIndex: [ :eachRule :index |
		rules add: (MCPMethodRewriteRuleSpec fromDictionary: eachRule request: request index: index) ].
	ruleClassNames do: [ :eachName |
		rules addAll: (MCPMethodRewriteRuleSpec specsForRuleClassNamed: eachName startingAt: rules size + 1) ].
	apply := request booleanArgumentNamed: 'confirm' default: false.
	scopeQuery := aTool methodScopeQueryFromRequest: request.
	scopeQuery requireCompleteScope
]

{ #category : 'converting' }
MCPMethodRewriteRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #confirm put: self apply.
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
