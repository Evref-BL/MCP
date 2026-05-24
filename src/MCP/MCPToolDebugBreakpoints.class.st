Class {
	#name : 'MCPToolDebugBreakpoints',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolDebugBreakpoints class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #page badgeIconNamed: #inspect
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints class >> toolName [

	^ 'debug-breakpoints'
]

{ #category : 'private - execution' }
MCPToolDebugBreakpoints >> commandForRequest: debugRequest [

	^ MCPDebugBreakpointsCommand tool: self request: debugRequest
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultDescription [

	^ 'Manage transient Pharo DebugPoint breakpoints for agent debugging. Supports method-entry and source-interval AST breakpoints; file/line breakpoints are intentionally not emulated.'
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #inspect) }
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   stringEnumSchemaPropertyNamed: 'operation'
					   description:
						   'Breakpoint operation. Defaults to list when omitted.'
					   values: MCPDebugBreakpointsRequest supportedOperations
					   default: 'list').
				  (self
					   schemaPropertyNamed: 'breakpointId'
					   type: 'string'
					   description:
						   'Opaque breakpoint identifier returned by a set or list operation.').
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
						   'Class that owns the method to instrument for a set operation.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description:
						   'Selector of the method to instrument for a set operation.').
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
						   'One-based source stop offset for sourceInterval breakpoints.') };
		  required: #(  );
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultName [

	^ 'debug-breakpoints'
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

{ #category : 'defaults' }
MCPToolDebugBreakpoints >> defaultTitle [

	^ 'Debug Breakpoints'
]

{ #category : 'executing' }
MCPToolDebugBreakpoints >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :debugRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: debugRequest) execute.
				  commandResult isError
					  ifTrue: [
							  self
								  errorResultText: commandResult summary
								  details: commandResult errorDetails ]
					  ifFalse: [
							  self
								  successResultText: commandResult summary
								  data: commandResult data
								  warnings: commandResult warnings ] ]
		  onError: [ :error :ignored |
				  self
					  errorResultText: (error messageText ifNil: [ error asString ])
					  details: ((error isKindOf: MCPCommandError)
							   ifTrue: [ error structuredDetails ]
							   ifFalse: [ self errorDetailsFor: error ]) ]
]

{ #category : 'private - request' }
MCPToolDebugBreakpoints >> parsedRequestFromToolRequest: request [

	^ MCPDebugBreakpointsRequest fromRequest: request tool: self
]
