Extension { #name : 'EpSessionSnapshot' }

{ #category : '*MCP-IDE' }
EpSessionSnapshot >> mcpIsImageSave [
	"Epicea logs a snapshot when the image is saved without quitting."

	^ true
]
