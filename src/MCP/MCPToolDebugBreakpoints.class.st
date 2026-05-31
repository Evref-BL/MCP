"
Shared implementation for focused transient Pharo DebugPoint breakpoint tools. It supports method-entry and source-interval AST breakpoints for agent debugging.
"
Class {
	#name : 'MCPToolDebugBreakpoints',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugBreakpoints class >> isAbstract [

	^ self = MCPToolDebugBreakpoints
]

{ #category : 'private - execution' }
MCPToolDebugBreakpoints >> commandForRequest: debugRequest [

	^ MCPDebugBreakpointsCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultOutputSchema [

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
