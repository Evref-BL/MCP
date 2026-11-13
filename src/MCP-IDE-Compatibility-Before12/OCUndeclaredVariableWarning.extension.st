Extension { #name : 'OCUndeclaredVariableWarning' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
OCUndeclaredVariableWarning >> mcpErrorPosition [
	"Before Pharo 12, the warning knows its node, not its position."

	^ self node ifNotNil: [ :aNode | aNode start ]
]
