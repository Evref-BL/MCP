Class {
	#name : 'MCPToolDebugBreakpointOperation',
	#superclass : 'MCPToolDebugBreakpoints',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolDebugBreakpointOperation class >> isAbstract [

	^ self = MCPToolDebugBreakpointOperation
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> breakpointIdSchemaProperty [

	^ self
		  schemaPropertyNamed: 'breakpointId'
		  type: 'string'
		  description:
		  'Opaque breakpoint identifier returned by debug_breakpoint_set or debug_breakpoint_list.'
]

{ #category : 'private - operations' }
MCPToolDebugBreakpointOperation >> breakpointOperationSpec [

	self subclassResponsibility
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

{ #category : 'defaults' }
MCPToolDebugBreakpointOperation >> defaultDescription [

	^ self breakpointOperationSpec at: #description
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
MCPToolDebugBreakpointOperation >> defaultTitle [

	^ self breakpointOperationSpec at: #title
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> inputProperties [

	^ self breakpointOperationSpec
		  at: #inputProperties
		  ifAbsent: [ #(  ) ]
]

{ #category : 'private - operations' }
MCPToolDebugBreakpointOperation >> operationName [

	^ self breakpointOperationSpec at: #operation
]

{ #category : 'private - request' }
MCPToolDebugBreakpointOperation >> parsedRequestFromToolRequest: request [

	| arguments focusedRequest |
	arguments := request arguments copy.
	arguments at: #operation put: self operationName.
	focusedRequest := MCPToolRequest new
		                  tool: self;
		                  arguments: arguments;
		                  yourself.
	^ MCPDebugBreakpointsRequest fromRequest: focusedRequest tool: self
]

{ #category : 'private - schema' }
MCPToolDebugBreakpointOperation >> requiredInputProperties [

	^ self breakpointOperationSpec
		  at: #requiredProperties
		  ifAbsent: [ #(  ) ]
]
