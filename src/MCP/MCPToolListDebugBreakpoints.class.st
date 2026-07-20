"
Concrete debug_breakpoint_list tool. It lists tracked transient DebugPoint breakpoints through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolListDebugBreakpoints',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListDebugBreakpoints class >> toolName [

	^ 'debug_breakpoint_list'
]

{ #category : 'private - specs' }
MCPToolListDebugBreakpoints >> breakpointToolSpec [

	^ {
		  (#title -> 'List Debug Breakpoints').
		  (#description
		   -> 'List tracked transient Pharo DebugPoint breakpoints.').
		  (#action -> 'list') } asDictionary
]

{ #category : 'metadata' }
MCPToolListDebugBreakpoints >> mutability [

	^ 'read'
]

{ #category : 'metadata' }
MCPToolListDebugBreakpoints >> risk [

	^ 'low'
]
