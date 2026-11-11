Extension { #name : 'OCNotice' }

{ #category : '*MCP-Compatibility-From13' }
OCNotice >> mcpMethodNode [

	^ self node ifNotNil: [ :noticeNode | noticeNode methodNode ]
]
