Extension { #name : 'EpMethodAddition' }

{ #category : '*MCP-IDE' }
EpMethodAddition >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo addSourceAfter: self sourceCode
]

{ #category : '*MCP-IDE' }
EpMethodAddition >> mcpMethodBeforeChange [
	"The method as it was before the change, nil when there was none."

	^ nil
]

{ #category : '*MCP-IDE' }
EpMethodAddition >> mcpVersionKind [
	"What the change did to its method, as a method version names it."

	^ 'added'
]
