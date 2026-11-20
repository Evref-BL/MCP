Extension { #name : 'MCPRewriteMethodsCommand' }

{ #category : '*MCP-IDE-Compatibility-Before13' }
MCPRewriteMethodsCommand >> applyChanges: changes [
	"Before Pharo 13, the change manager has no performChanges:, so each change goes through performChange:."

	changes do: [ :each | RBRefactoryChangeManager instance performChange: each ]
]
