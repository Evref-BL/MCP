"
Renraku rule that warns when MCP-authored methods use respondsTo:.

In ordinary Smalltalk code, collaborators and internal APIs should be modeled directly instead of guarded reflectively. Version drift belongs in PharoCompatibility, and external APIs should prefer testing protocol or class hierarchy checks before falling back to respondsTo:.
"
Class {
	#name : 'MCPRespondsToUsageRule',
	#superclass : 'ReAbstractRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'testing' }
MCPRespondsToUsageRule class >> checksMethod [

	^ true
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> group [

	^ self designFlawGroup
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> rationale [

	^ 'Avoid respondsTo: in ordinary Smalltalk code. Prefer clear collaborator contracts, testing protocol, isKindOf:, or PharoCompatibility for version differences; use respondsTo: only for truly reflective external APIs.'
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> ruleName [

	^ 'Avoid respondsTo:'
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> severity [

	^ #warning
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> uniqueIdentifierName [

	^ 'MCPRespondsToUsageRule'
]

{ #category : 'running' }
MCPRespondsToUsageRule >> check: aMethod forCritiquesDo: aCriticBlock [

	| respondsToSends |
	respondsToSends := aMethod sendNodes select: [ :sendNode |
		                   sendNode selector = #respondsTo: ].
	respondsToSends do: [ :sendNode |
			aCriticBlock cull: (self
					 createTrivialCritiqueOn: aMethod
					 intervalOf: sendNode
					 hint:
					 'Use collaborator contracts, testing protocol, isKindOf:, or PharoCompatibility first.') ]
]

{ #category : 'accessing' }
MCPRespondsToUsageRule >> name [

	^ self class ruleName
]
