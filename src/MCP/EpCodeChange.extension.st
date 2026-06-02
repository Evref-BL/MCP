Extension { #name : 'EpCodeChange' }

{ #category : '*MCP' }
EpCodeChange >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #affectedPackageName ifTrue: [
		^ self affectedPackageName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
