Extension { #name : 'OCNotice' }

{ #category : '*MCP-IDE-Compatibility-From13' }
OCNotice >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-IDE-Compatibility-From13' }
OCNotice >> mcpMethodNode [

	^ self node ifNotNil: [ :noticeNode | noticeNode methodNode ]
]

{ #category : '*MCP-IDE-Compatibility-From13' }
OCNotice >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
