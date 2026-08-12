"
Concrete debug_breakpoint_set tool. It installs a transient DebugPoint breakpoint on a method or source interval through MCPToolDebugBreakpointOperation.
"
Class {
	#name : 'MCPToolSetDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSetDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_set'
]

{ #category : 'private - specs' }
MCPToolSetDebugBreakpoint >> breakpointToolSpec [

	^ {
		  (#title -> 'Set Debug Breakpoint').
		  (#description -> 'Install a transient Pharo DebugPoint breakpoint on a method or source interval.').
		  (#action -> 'set').
		  (#inputProperties -> self breakpointTargetInputProperties).
		  (#requiredProperties -> #( 'className' 'selector' )) } asDictionary
]
