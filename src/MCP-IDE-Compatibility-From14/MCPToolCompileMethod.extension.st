Extension { #name : 'MCPToolCompileMethod' }

{ #category : '*MCP-IDE-Compatibility-From14' }
MCPToolCompileMethod >> compileFailures [
	"An error fails a compile, the compiler's verdict on the source among them. A notification is resumed as at the boundary of the call, as one raised once the method is installed by whoever listens to method changes."

	^ Error
]
