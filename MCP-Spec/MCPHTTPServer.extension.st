Extension { #name : 'MCPHTTPServer' }

{ #category : '*MCP-Spec' }
MCPHTTPServer >> isListening [

	^ server isListening
]

{ #category : '*MCP-Spec' }
MCPHTTPServer >> isRunning [

	^ server isRunning
]

{ #category : '*MCP-Spec' }
MCPHTTPServer >> localUrl [

	^ server localUrl
]
