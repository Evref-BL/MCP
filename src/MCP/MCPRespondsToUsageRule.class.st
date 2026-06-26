"
Renraku rule that warns when MCP-authored production methods use respondsTo:.

In ordinary Smalltalk code, collaborators and internal APIs should be modeled directly instead of guarded reflectively. Version drift belongs in PharoCompatibility, and external APIs should prefer testing protocol or explicit capability messages before falling back to reflective selector probes.
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
MCPRespondsToUsageRule class >> forbiddenSelector [

	^ #respondsTo:
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> group [

	^ #'Design Flaws'
]

{ #category : 'accessing' }
MCPRespondsToUsageRule class >> rationale [

	^ 'Avoid respondsTo: in ordinary Smalltalk production code. Prefer clear collaborator contracts, testing protocol, or PharoCompatibility for version differences; reserve reflective selector probes for true meta-programming boundaries.'
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

	aMethod sendNodes do: [ :sendNode |
			sendNode selector = self class forbiddenSelector ifTrue: [
					aCriticBlock cull: (self
							 createTrivialCritiqueOn: aMethod
							 intervalOf: sendNode
							 hint:
							 'Use collaborator contracts, testing protocol, or PharoCompatibility first.') ] ]
]

{ #category : 'accessing' }
MCPRespondsToUsageRule >> name [

	^ self class ruleName
]
