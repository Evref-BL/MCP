Extension { #name : 'OCShadowVariableWarning' }

{ #category : '*MCP-Compatibility-Before12' }
OCShadowVariableWarning >> mcpDefaultAction [
	"Pharo 11 refuses a temporary that shadows an instance variable when compiling interactively, as a tool does. From Pharo 12 on the method compiles and a critique reports the shadowing, so this answers what Pharo 11 answers when not interactive."

	^ nil
]
