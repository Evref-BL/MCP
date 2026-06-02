Extension { #name : 'EpMonticelloVersionSave' }

{ #category : '*MCP' }
EpMonticelloVersionSave >> mcpChangeHistoryValueForSelector: aSelector [

	(aSelector = #affectedPackageName or: [ aSelector = #packageName ])
		ifTrue: [ ^ self packageName ].
	^ super mcpChangeHistoryValueForSelector: aSelector
]
