"
What MCP's own critique rules share, whether they match a pattern or walk a method: their metadata, and the gate that keeps them for an agent. A rule implements agentCheck:forCritiquesDo: where a Renraku rule implements check:forCritiquesDo:.
"
Trait {
	#name : 'TMCPAgentRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
TMCPAgentRule classSide >> group [

	^ #'Design Flaws'
]

{ #category : 'accessing' }
TMCPAgentRule classSide >> severity [

	^ #warning
]

{ #category : 'manifest' }
TMCPAgentRule classSide >> uniqueIdentifierName [
	"The key a manifest keeps the rule's false positives under, so it stays this String."

	^ self name asString
]

{ #category : 'running' }
TMCPAgentRule >> agentCheck: anEntity forCritiquesDo: aCriticBlock [
	"Give aCriticBlock each critique of anEntity, as check:forCritiquesDo: does for a rule that answers everyone."

	self explicitRequirement
]

{ #category : 'running' }
TMCPAgentRule >> check: anEntity forCritiquesDo: aCriticBlock [
	"MCP's rules answer an agent only, so the browser and Iceberg, which critique outside MCPAgentCritiquing, never show them."

	MCPAgentCritiquing value ifFalse: [ ^ self ].
	self agentCheck: anEntity forCritiquesDo: aCriticBlock
]

{ #category : 'accessing' }
TMCPAgentRule >> name [
	"Before Pharo 13, ReAbstractRule leaves name to its subclasses."

	^ self class ruleName
]
