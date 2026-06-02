Extension { #name : 'EpMethodChange' }

{ #category : '*MCP' }
EpMethodChange >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #behaviorAffectedName ifTrue: [
		^ self behaviorAffectedName ].
	aSelector = #methodAffectedSelector ifTrue: [
		^ self methodAffectedSelector ].
	aSelector = #selector ifTrue: [ ^ self methodAffectedSelector ].
	aSelector = #methodAffectedProtocol ifTrue: [
		^ self methodAffectedProtocol ].
	aSelector = #protocol ifTrue: [ ^ self methodAffectedProtocol ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
