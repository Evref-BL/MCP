Extension { #name : 'OmReference' }

{ #category : '*MCP' }
OmReference >> mcpChangeHistoryReferenceString [

	^ self shortName asString
]

{ #category : '*MCP' }
OmReference >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #globalName ifTrue: [ ^ self globalName ].
	aSelector = #localName ifTrue: [ ^ self localName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
