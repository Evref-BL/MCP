Extension { #name : 'Notification' }

{ #category : '*MCP' }
Notification >> mcpDefaultAction [
	"The value a tool resumes me with: what the image would have done had nobody handled me, unless that is to ask a person, whom a tool call has none of."

	^ self defaultAction
]
