Extension { #name : 'MethodAnnouncement' }

{ #category : '*MCP' }
MethodAnnouncement >> mcpAffectedPackages [

	^ self method ifNil: [ #(  ) ] ifNotNil: [ :compiledMethod | { compiledMethod package } ]
]
