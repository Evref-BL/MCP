"
Request DTO for critique_run. It carries the resolved scope, selected Renraku rule classes, and hit pagination settings.
"
Class {
	#name : 'MCPCritiqueRunRequest',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'scopeQuery',
		'ruleClasses',
		'limit',
		'offset'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPCritiqueRunRequest class >> fromRequest: request tool: aTool [

	^ self new
		  scopeQuery: (aTool methodScopeQueryFromRequest: request);
		  ruleClasses: (aTool ruleClassesFromRequest: request);
		  limit: (request nonNegativeIntegerArgumentNamed: 'limit' default: aTool defaultPageLimit);
		  offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'converting' }
MCPCritiqueRunRequest >> asDictionary [

	^ {
		  (#scope -> self scopeQuery asDictionary).
		  (#ruleClasses -> (self ruleClasses collect: [ :each | each name asString ])).
		  (#limit -> self limit).
		  (#offset -> self offset) } asDictionary
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> limit [

	^ limit
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> offset [

	^ offset
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> offset: anInteger [

	offset := anInteger
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> ruleClasses [

	^ ruleClasses ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> ruleClasses: someRuleClasses [

	ruleClasses := someRuleClasses ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> scopeQuery [

	^ scopeQuery
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> scopeQuery: aScopeQuery [

	scopeQuery := aScopeQuery
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> warnings [

	^ self scopeQuery warnings
]
