Extension { #name : 'Notification' }

{ #category : '*MCP' }
Notification >> mcpDefaultAction [
	"The value a tool resumes me with: what the image would have done had nobody handled me, unless that is to ask a person, whom a tool call has none of."

	^ self defaultAction
]

{ #category : '*MCP' }
Notification >> mcpResume [
	"Resumes me with the value the image itself would have produced. The default action may signal notifications of its own, and a handler is suspended while its block runs, so those would otherwise escape the handler that resumes me: Deprecation>>defaultAction logs, and logging signals DeprecationPerformedNotification.

	A warning is where that value is an error rather than a value. Warning>>defaultAction treats the absence of a handler as one and raises, and a deprecation reaches the same line in an image set to raise them, so code that only warned would fail. The default action still runs, for the log and the rewrite a deprecation performs, and what it raises instead of answering is dropped."

	^ self resume: ([
			   [ self mcpDefaultAction ]
				   on: Notification
				   do: [ :nested | nested mcpResume ] ]
			   on: UnhandledError
			   do: [ :unhandled | unhandled return: nil ])
]

{ #category : '*MCP' }
Notification >> mcpResumedDescription [
	"How a tool that resumed me with mcpResume reports me: my description, unless that says something other than what resuming me did."

	^ self description
]

{ #category : '*MCP' }
Notification >> mcpResumesAtToolBoundary [
	"A notification is not a failed call, so the boundary around a tool call resumes it."

	^ true
]
