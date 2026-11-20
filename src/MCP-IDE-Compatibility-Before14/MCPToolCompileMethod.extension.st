Extension { #name : 'MCPToolCompileMethod' }

{ #category : '*MCP-IDE-Compatibility-Before14' }
MCPToolCompileMethod >> compileFailures [
	"Before Pharo 14, the compiler gives some of its verdicts on a source as notifications, an undeclared variable among them, so any exception fails a compile."

	^ Exception
]
