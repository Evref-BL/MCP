Class {
	#name : 'MCPToolSetDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSetDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_set'
]

{ #category : 'private - operations' }
MCPToolSetDebugBreakpoint >> breakpointOperationSpec [

	^ {
		  (#title -> 'Set Debug Breakpoint').
		  (#description
		   ->
		   'Install a transient Pharo DebugPoint breakpoint on a method or source interval.').
		  (#operation -> 'set').
		  (#inputProperties -> self breakpointTargetInputProperties).
		  (#requiredProperties -> #( 'className' 'selector' )) }
		  asDictionary
]
