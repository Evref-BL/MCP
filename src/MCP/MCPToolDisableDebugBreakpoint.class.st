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

{ #category : 'private - operations' }
MCPToolDisableDebugBreakpoint >> breakpointOperationSpec [

	^ {
		  (#title -> 'Disable Debug Breakpoint').
		  (#description
		   -> 'Disable one tracked transient Pharo DebugPoint breakpoint.').
		  (#operation -> 'disable').
		  (#inputProperties -> { self breakpointIdSchemaProperty }).
		  (#requiredProperties -> #( 'breakpointId' )) } asDictionary
]
