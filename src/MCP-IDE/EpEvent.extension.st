Extension { #name : 'EpEvent' }

{ #category : '*MCP-IDE' }
EpEvent >> mcpChangeHistoryEntryKind [

	^ 'other'
]

{ #category : '*MCP-IDE' }
EpEvent >> mcpIsMethodRemoval [
	"Whether the event removed a method, which the history can bring back."

	^ false
]
