Extension { #name : 'MCPTool' }

{ #category : '*MCP-Compatibility-Before13' }
MCPTool >> duringCall: aBlock [
	"Before Pharo 13, Pharo asks for the author's name when it signs a change or a package and the image has none, and a tool takes that request for the failure of its call. During a call, a missing name is Anonymous, which is what Pharo records when the request is cancelled; the image goes back to having none after it."

	Author uniqueInstance fullNamePerSe isEmptyOrNil ifFalse: [ ^ aBlock value ].
	^ Author useAuthor: 'Anonymous' during: aBlock
]
