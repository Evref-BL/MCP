Extension { #name : 'EpEvent' }

{ #category : '*MCP-IDE' }
EpEvent >> mcpChangeHistoryEntryKind [

	^ 'other'
]

{ #category : '*MCP-IDE' }
EpEvent >> mcpIsImageSave [
	"Whether the image was saved here, its session going on after it: what the session wrote before is the image's own from then on."

	^ false
]
