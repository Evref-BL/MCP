Extension { #name : 'MCPPlaygroundRequestor' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPPlaygroundRequestor >> notify: aString at: anInteger in: aStream [
	"Pharo 11 hands a compile error to its requestor, then calls the failBlock with nothing. The error is signalled from here instead, with what Pharo 12 hands the failBlock."

	^ (MCPSyntaxError messageText: (aString withoutSuffix: ' ->') position: anInteger) signal
]
