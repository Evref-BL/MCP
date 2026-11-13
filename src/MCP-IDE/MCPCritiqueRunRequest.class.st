"
Request DTO for critique_run. It carries the resolved scope, selected Renraku rule classes and whether the caller named them, and hit pagination settings. It keeps the manifest rules of each package it meets, for the length of the call.
"
Class {
	#name : 'MCPCritiqueRunRequest',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'scopeQuery',
		'ruleClasses',
		'limit',
		'offset',
		'namesRules',
		'manifestRules'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPCritiqueRunRequest class >> fromRequest: request tool: aTool [

	^ self new
		  scopeQuery: (aTool methodScopeQueryFromRequest: request);
		  ruleClasses: (aTool ruleClassesFromRequest: request);
		  namesRules: (request uniqueStringCollectionArgumentNamed: 'ruleClasses') isNotEmpty;
		  limit: aTool defaultPageLimit;
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
MCPCritiqueRunRequest >> manifestRulesFor: anEntity [
	"Looking a package's manifest up walks its classes, so each package's is looked up once per call."

	^ (manifestRules ifNil: [ manifestRules := IdentityDictionary new ])
		  at: anEntity package
		  ifAbsentPut: [ MCPManifestRules for: anEntity ]
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> namesRules [
	"Whether the caller named the rules, which then run though the image has them off."

	^ namesRules ifNil: [ false ]
]

{ #category : 'accessing' }
MCPCritiqueRunRequest >> namesRules: aBoolean [

	namesRules := aBoolean
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
