"
Concrete debug_session tool. It answers the debuggers a person has open, or the state of one of them.

Called with nothing, it lists what is open, whether or not MCP has attached to it. Called with a reference, it attaches that debugger if it is not attached yet and answers its state, so reaching a frame is one call rather than three. No tool starts a session: a session is a debugger somebody opened.
"
Class {
	#name : 'MCPToolDebugSession',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugSession class >> toolName [

	^ 'debug_session'
]

{ #category : 'metadata' }
MCPToolDebugSession >> additionalKeywords [

	^ super additionalKeywords , #( 'attach' 'open' 'candidate' 'stack' 'variables' 'paused' )
]

{ #category : 'private - execution' }
MCPToolDebugSession >> commandForRequest: debugRequest [

	^ MCPDebugSessionsCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugSession >> description [

	^ 'List the debuggers open in the image, or answer one of them: its stack, selected frame, source, variables and repair actions. Pass the reference a listing gave to attach and read it in one call.'
]

{ #category : 'metadata' }
MCPToolDebugSession >> inputProperties [

	^ { (self
		   schemaPropertyNamed: 'session'
		   type: 'string'
		   description: 'A debugger or session reference from a listing. Left out, the open debuggers are listed.') }
]

{ #category : 'private - request' }
MCPToolDebugSession >> parsedRequestFromToolRequest: request [

	^ MCPDebugSessionsRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugSession >> requiredInputProperties [

	^ #(  )
]

{ #category : 'metadata' }
MCPToolDebugSession >> title [

	^ 'Open Debuggers'
]
