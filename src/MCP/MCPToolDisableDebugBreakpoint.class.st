"
Concrete debug_breakpoint_disable tool. It disables one tracked transient DebugPoint breakpoint through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolDisableDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolDisableDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_disable'
]

{ #category : 'private - specs' }
MCPToolDisableDebugBreakpoint >> breakpointToolSpec [

	^ {
		  (#title -> 'Disable Debug Breakpoint').
		  (#description
		   -> 'Disable one tracked transient Pharo DebugPoint breakpoint.').
		  (#action -> 'disable').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
