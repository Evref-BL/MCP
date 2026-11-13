Extension { #name : 'MCPTool' }

{ #category : '*MCP-Compatibility-Before12' }
MCPTool >> duringCall: aBlock [
	"Pharo 11 asks for the author's name when code changes and the image has none, and the tools that compile take that request for the failure of the call. During a call, a missing name is Anonymous, which is what Pharo records when the request is cancelled; the image goes back to having none after it."

	Author uniqueInstance fullNamePerSe isEmptyOrNil ifFalse: [ ^ aBlock value ].
	^ Author useAuthor: 'Anonymous' during: aBlock
]
