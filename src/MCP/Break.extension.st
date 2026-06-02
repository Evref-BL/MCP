Extension { #name : 'Break' }

{ #category : '*MCP' }
Break >> mcpDebugCapturedReason [

	^ 'debugStop'
]

{ #category : '*MCP' }
Break >> mcpDebugStartContext [

	^ self signalerContext sender
]
