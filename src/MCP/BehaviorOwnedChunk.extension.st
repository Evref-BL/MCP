Extension { #name : 'BehaviorOwnedChunk' }

{ #category : '*MCP' }
BehaviorOwnedChunk >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #behaviorName ifTrue: [ ^ self behaviorName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
