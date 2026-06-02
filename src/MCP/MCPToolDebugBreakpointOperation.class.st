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
		  description:
		  'Opaque breakpoint identifier returned by debug_breakpoint_set or debug_breakpoint_list.'
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> breakpointTargetInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'Class that owns the method to instrument.').
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description: 'Selector of the method to instrument.').
		  (self
			   booleanSchemaPropertyNamed: 'classSide'
			   description: 'Whether selector is resolved on the class side.'
			   default: false).
		  (self
			   stringEnumSchemaPropertyNamed: 'targetKind'
			   description:
			   'Breakpoint target kind inside the resolved method.'
			   values: MCPDebugBreakpointsRequest supportedTargetKinds
			   default: 'method').
		  (self
			   integerSchemaPropertyNamed: 'sourceStart'
			   description:
			   'One-based source start offset for sourceInterval breakpoints.').
		  (self
			   integerSchemaPropertyNamed: 'sourceStop'
			   description:
			   'One-based source stop offset for sourceInterval breakpoints.') }
]

{ #category : 'private - specs' }
MCPToolDebugBreakpointOperation >> breakpointToolSpec [

	self subclassResponsibility
]

{ #category : 'private - execution' }
MCPToolDebugBreakpointOperation >> commandForRequest: debugRequest [

	^ MCPDebugBreakpointsCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugBreakpointOperation >> defaultDescription [

	^ self breakpointToolSpec at: #description
]

{ #category : 'defaults' }
MCPToolDebugBreakpointOperation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugBreakpointOperation >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'breakpoints'
					   type: 'array'
					   description:
					   'Breakpoint records returned by list or clear operations.').
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description:
					   'Total number of tracked transient breakpoints after the operation.').
				  (self
					   schemaPropertyNamed: 'breakpointId'
					   type: 'string'
					   description: 'Opaque breakpoint identifier.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'Class that owns the instrumented method.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'Instrumented method selector.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
					   'Whether the instrumented method is on the class side.').
				  (self
					   schemaPropertyNamed: 'targetKind'
					   type: 'string'
					   description: 'Breakpoint target kind.').
				  (self
					   integerSchemaPropertyNamed: 'sourceStart'
					   description: 'Resolved source start offset.').
				  (self
					   integerSchemaPropertyNamed: 'sourceStop'
					   description: 'Resolved source stop offset.').
				  (self
					   schemaPropertyNamed: 'nodeClassName'
					   type: 'string'
					   description: 'AST node class used as the DebugPoint target.').
				  (self
					   booleanSchemaPropertyNamed: 'enabled'
					   description: 'Whether the breakpoint is enabled.').
				  (self
					   booleanSchemaPropertyNamed: 'removed'
					   description:
					   'True when a remove operation removed this breakpoint.').
				  (self
					   integerSchemaPropertyNamed: 'removedCount'
					   description:
					   'Number of breakpoints removed by a clear operation.').
				  (self
					   schemaPropertyNamed: 'targetString'
					   type: 'string'
					   description: 'Human-readable DebugPoint target string.').
				  (self
					   schemaPropertyNamed: 'createdAt'
					   type: 'string'
					   description: 'Creation timestamp string.').
				  (self
					   schemaPropertyNamed: 'capabilities'
					   type: 'object'
					   description:
					   'Breakpoint capability gates used for this response.') }
		  required: #( 'totalCount' 'capabilities' )
]

{ #category : 'defaults' }
MCPToolDebugBreakpointOperation >> defaultTitle [

	^ self breakpointToolSpec at: #title
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> inputProperties [

	^ self breakpointToolSpec
		  at: #inputProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - request' }
MCPToolDebugBreakpointOperation >> parsedRequestFromToolRequest: request [

	^ MCPDebugBreakpointsRequest
		  fromRequest: request
		  tool: self
		  operation: self actionName
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> requiredInputProperties [

	^ self breakpointToolSpec
		  at: #requiredProperties
		  ifAbsent: [ #(  ) ]
]
