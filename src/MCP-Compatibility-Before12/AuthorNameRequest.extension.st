Extension { #name : 'AuthorNameRequest' }

{ #category : '*MCP-Compatibility-Before12' }
AuthorNameRequest >> mcpDefaultAction [
	"Asking for an author opens a dialog nobody answers during a tool call. Without a name, Pharo records Anonymous, as when the dialog is cancelled; from Pharo 12 on it records no author at all."

	^ nil
]
