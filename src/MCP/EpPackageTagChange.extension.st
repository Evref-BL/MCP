Extension { #name : 'EpPackageTagChange' }

{ #category : '*MCP' }
EpPackageTagChange >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #packageName ifTrue: [ ^ self packageName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
