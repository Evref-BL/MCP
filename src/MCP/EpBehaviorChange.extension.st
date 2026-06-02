Extension { #name : 'EpBehaviorChange' }

{ #category : '*MCP' }
EpBehaviorChange >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #behaviorAffectedName ifTrue: [
		^ self behaviorAffectedName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
