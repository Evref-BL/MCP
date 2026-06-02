Extension { #name : 'EpPackageChange' }

{ #category : '*MCP' }
EpPackageChange >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #packageName ifTrue: [ ^ self packageName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
