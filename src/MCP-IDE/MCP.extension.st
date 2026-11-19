Extension { #name : 'MCP' }

{ #category : '*MCP-IDE' }
MCP class >> pharoCodeInstructions [
	"The everyday workflow on Pharo code, which a server gives its client only while it advertises every tool named here."

	<discoveryInstructions>
	^ 'Pharo code lives in the running image: find it with class_search or method_search, read with method_get, write with method_compile, check with test_run.'
]
