Class {
	#name : 'MCPToolRemoveDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRemoveDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_remove'
]

{ #category : 'private - operations' }
MCPToolRemoveDebugBreakpoint >> breakpointOperationSpec [

	^ {
		  (#title -> 'Remove Debug Breakpoint').
		  (#description
		   -> 'Remove one tracked transient Pharo DebugPoint breakpoint.').
		  (#operation -> 'remove').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
