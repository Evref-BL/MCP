"
Concrete debug_breakpoint_clear tool. It removes all tracked transient DebugPoint breakpoints through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolClearDebugBreakpoints',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolClearDebugBreakpoints class >> toolName [

	^ 'debug_breakpoint_clear'
]

{ #category : 'private - specs' }
MCPToolClearDebugBreakpoints >> breakpointToolSpec [

	^ {
		  (#title -> 'Clear Debug Breakpoints').
		  (#description
		   -> 'Remove all tracked transient Pharo DebugPoint breakpoints.').
		  (#action -> 'clear') } asDictionary
]
