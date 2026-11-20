Extension { #name : 'MCPRewriteMethodsCommand' }

{ #category : '*MCP-IDE-Compatibility-From13' }
MCPRewriteMethodsCommand >> applyChanges: changes [

	ReChangeManager instance performChanges: changes
]
