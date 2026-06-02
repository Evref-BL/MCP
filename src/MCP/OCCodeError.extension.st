Extension { #name : 'OCCodeError' }

{ #category : '*MCP' }
OCCodeError >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP' }
OCCodeError >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP' }
OCCodeError >> mcpMutationFailureNotice [

	^ self notice ifNil: [ self ]
]

{ #category : '*MCP' }
OCCodeError >> mcpNoticeNode [

	^ self node
]
