Extension { #name : 'EpMonticelloVersionsLoad' }

{ #category : '*MCP' }
EpMonticelloVersionsLoad >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #affectedPackageName ifTrue: [
		^ self affectedPackageName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
