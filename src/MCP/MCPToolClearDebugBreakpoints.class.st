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

{ #category : 'private - operations' }
MCPToolClearDebugBreakpoints >> breakpointOperationSpec [

	^ {
		  (#title -> 'Clear Debug Breakpoints').
		  (#description
		   -> 'Remove all tracked transient Pharo DebugPoint breakpoints.').
		  (#operation -> 'clear') } asDictionary
]
