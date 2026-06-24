"
Concrete debug_breakpoint_enable tool. It enables one tracked transient DebugPoint breakpoint through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolEnableDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolEnableDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_enable'
]

{ #category : 'private - specs' }
MCPToolEnableDebugBreakpoint >> breakpointToolSpec [

	^ {
		  (#title -> 'Enable Debug Breakpoint').
		  (#description
		   -> 'Enable one tracked transient Pharo DebugPoint breakpoint.').
		  (#action -> 'enable').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
