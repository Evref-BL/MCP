Class {
	#name : 'MCPToolListDebugBreakpoints',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListDebugBreakpoints class >> toolName [

	^ 'debug_breakpoint_list'
]

{ #category : 'private - operations' }
MCPToolListDebugBreakpoints >> breakpointOperationSpec [

	^ {
		  (#title -> 'List Debug Breakpoints').
		  (#description
		   -> 'List tracked transient Pharo DebugPoint breakpoints.').
		  (#operation -> 'list') } asDictionary
]
