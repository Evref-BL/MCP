"
Shared implementation for transient Pharo DebugPoint breakpoint operation tools.

It defines per-tool breakpoint inputs and supports method-entry and source-interval AST breakpoints for agent debugging.
"
Class {
	#name : 'MCPToolDebugBreakpointOperation',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugBreakpointOperation class >> isAbstract [

	^ self = MCPToolDebugBreakpointOperation
]

{ #category : 'private - actions' }
MCPToolDebugBreakpointOperation >> actionName [

	^ self breakpointToolSpec at: #action
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> breakpointIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'breakpointId'
		  type: 'string'
		  description: 'Opaque breakpoint identifier returned by debug_breakpoint_set or debug_breakpoint_list.'
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> breakpointTargetInputProperties [

	^ {
		  (self schemaPropertyNamed: 'className' type: 'string' description: 'Class that owns the method to instrument.').
		  (self schemaPropertyNamed: 'selector' type: 'string' description: 'Selector of the method to instrument.').
		  (self booleanSchemaPropertyNamed: 'classSide' description: 'Whether selector is resolved on the class side.' default: false).
		  (self
			   stringEnumSchemaPropertyNamed: 'targetKind'
			   description: 'Breakpoint target kind inside the resolved method.'
			   values: MCPDebugBreakpointsRequest supportedTargetKinds
			   default: 'method').
		  (self integerSchemaPropertyNamed: 'sourceStart' description: 'One-based source start offset for sourceInterval breakpoints.').
		  (self integerSchemaPropertyNamed: 'sourceStop' description: 'One-based source stop offset for sourceInterval breakpoints.') }
]

{ #category : 'private - specs' }
MCPToolDebugBreakpointOperation >> breakpointToolSpec [

	self subclassResponsibility
]

{ #category : 'private - execution' }
MCPToolDebugBreakpointOperation >> commandForRequest: debugRequest [

	^ MCPDebugBreakpointsCommand tool: self request: debugRequest
]

{ #category : 'metadata' }
MCPToolDebugBreakpointOperation >> description [

	^ self breakpointToolSpec at: #description
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> inputProperties [

	^ self breakpointToolSpec at: #inputProperties ifAbsent: [ #(  ) ]
]

{ #category : 'private - request' }
MCPToolDebugBreakpointOperation >> parsedRequestFromToolRequest: request [

	^ MCPDebugBreakpointsRequest fromRequest: request tool: self operation: self actionName
]

{ #category : 'private - results' }
MCPToolDebugBreakpointOperation >> redundantKeys [
	"The breakpoint already names the method it is set on, and its kind says whether it watches the
	whole method or one node."

	^ super redundantKeys , #( targetString )
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> requiredInputProperties [

	^ self breakpointToolSpec at: #requiredProperties ifAbsent: [ #(  ) ]
]

{ #category : 'metadata' }
MCPToolDebugBreakpointOperation >> title [

	^ self breakpointToolSpec at: #title
]
