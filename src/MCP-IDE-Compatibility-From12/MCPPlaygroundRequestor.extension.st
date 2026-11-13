Extension { #name : 'MCPPlaygroundRequestor' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPPlaygroundRequestor >> notify: aString at: anInteger in: aStream [
	"Pharo 12 hands a compile error to its requestor as well as to the failBlock, which is where the error is reported from."

	^ nil
]
