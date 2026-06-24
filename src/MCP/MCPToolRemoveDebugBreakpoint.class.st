"
Concrete debug_breakpoint_remove tool. It removes one tracked transient DebugPoint breakpoint through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolRemoveDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_remove'
]

{ #category : 'private - specs' }
MCPToolRemoveDebugBreakpoint >> breakpointToolSpec [

	^ {
		  (#title -> 'Remove Debug Breakpoint').
		  (#description
		   -> 'Remove one tracked transient Pharo DebugPoint breakpoint.').
		  (#action -> 'remove').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
