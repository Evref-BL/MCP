Class {
	#name : 'MCPToolEnableDebugBreakpoint',
	#superclass : 'MCPToolDebugBreakpointOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolEnableDebugBreakpoint class >> toolName [

	^ 'debug_breakpoint_enable'
]

{ #category : 'private - operations' }
MCPToolEnableDebugBreakpoint >> breakpointOperationSpec [

	^ {
		  (#title -> 'Enable Debug Breakpoint').
		  (#description
		   -> 'Enable one tracked transient Pharo DebugPoint breakpoint.').
		  (#operation -> 'enable').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
