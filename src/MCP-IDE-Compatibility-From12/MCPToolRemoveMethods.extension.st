Extension { #name : 'MCPToolRemoveMethods' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPToolRemoveMethods >> forceRemoveSelectors: selectorSymbols from: aBehavior [

	| refactoring |
	refactoring := ReRemoveMethodsRefactoring selectors: selectorSymbols from: aBehavior.
	refactoring removeMethodChanges.
	refactoring performChanges
]
