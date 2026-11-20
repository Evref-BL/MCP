Extension { #name : 'OCShadowVariableWarning' }

{ #category : '*MCP-Compatibility-Before12' }
OCShadowVariableWarning >> mcpDefaultAction [
	"Before Pharo 12, Pharo refuses a temporary that shadows an instance variable when compiling interactively, as a tool does. From Pharo 12 on the method compiles and a critique reports the shadowing, so this answers what the older versions answer when not interactive."

	^ nil
]
