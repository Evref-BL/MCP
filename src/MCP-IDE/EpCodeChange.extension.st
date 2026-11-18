Extension { #name : 'EpCodeChange' }

{ #category : '*MCP-IDE' }
EpCodeChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addCodeChangeInfoFrom: self
]

{ #category : '*MCP-IDE' }
EpCodeChange >> mcpAddSourcesTo: anEntryInfo [
	"Only a method change has a source to show."

	
]
