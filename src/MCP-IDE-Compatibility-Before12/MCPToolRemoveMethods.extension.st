Extension { #name : 'MCPToolRemoveMethods' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPToolRemoveMethods >> forceRemoveSelectors: selectorSymbols from: aBehavior [

	| refactoring |
	refactoring := RBRemoveMethodRefactoring removeMethods: selectorSymbols from: aBehavior.
	refactoring transform.
	refactoring performChanges
]
