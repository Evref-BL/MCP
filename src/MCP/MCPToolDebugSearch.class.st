"
Concrete debug_search tool. It answers the debuggers a person has open in the image.

It is a query and nothing else. No session is started, attached, registered or remembered, so there is no reference to keep and nothing to clean up: ask again and the answer reflects whatever is open then. To act on what it shows, use the ordinary class and method tools.
"
Class {
	#name : 'MCPToolDebugSearch',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugSearch class >> toolName [

	^ 'debug_search'
]

{ #category : 'metadata' }
MCPToolDebugSearch >> additionalKeywords [

	^ #( 'debug' 'debugger' 'open' 'paused' 'stack' 'frame' 'exception' 'halt' )
]

{ #category : 'private - execution' }
MCPToolDebugSearch >> commandForRequest: debugRequest [

	^ MCPDebugSearchCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugSearch >> description [

	^ 'Answer the debuggers open in the image, each with its exception and the frames nearest the stop, including what those frames hold. Read-only: nothing is attached or kept, so ask again for the current picture.'
]

{ #category : 'metadata' }
MCPToolDebugSearch >> inputProperties [

	^ { (self
		   schemaPropertyNamed: 'query'
		   type: 'string'
		   description: 'Only answer debuggers whose name or exception contains this text. Left out, all of them are answered.') }
]

{ #category : 'private - request' }
MCPToolDebugSearch >> parsedRequestFromToolRequest: request [

	^ MCPDebugSearchRequest fromRequest: request tool: self
]

{ #category : 'metadata' }
MCPToolDebugSearch >> requiredInputProperties [

	^ #(  )
]

{ #category : 'metadata' }
MCPToolDebugSearch >> title [

	^ 'Open Debuggers'
]
