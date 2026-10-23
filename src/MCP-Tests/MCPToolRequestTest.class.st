"
Tests MCPToolRequest validation and typed argument access.
"
Class {
	#name : 'MCPToolRequestTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'tests' }
MCPToolRequestTest >> testHasArgumentNamedHandlesSymbolAndStringKeys [

	| request |
	request := MCPToolRequest tool: MCPToolEvaluate new arguments: { ('code' -> '1 + 1') } asDictionary.
	self assert: (request hasArgumentNamed: 'code').
	self assert: (request hasArgumentNamed: #code).
	self deny: (request hasArgumentNamed: 'missing')
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidRequestRaisesInvalidParameters [

	self
		should: [ MCPToolRequest tool: MCPToolSearchPackages new arguments: { (#offset -> 'ten') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidRequestRaisesToolInputErrorWithViolations [

	| error violation |
	[ MCPToolRequest tool: MCPToolSearchPackages new arguments: { (#offset -> 'ten') } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	self assert: error isNotNil.
	self assert: error toolName equals: 'package_search'.
	self assert: error violations size equals: 1.
	violation := error violations first.
	self assert: violation path equals: #( 'offset' ).
	self assert: violation keyword equals: 'type'.
	self assert: violation expected equals: 'integer'.
	self assert: violation actual equals: 'string'
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidToolInputErrorResponseIncludesViolations [

	| data error errorJson firstViolation response violations |
	[ MCPToolRequest tool: MCPToolSearchPackages new arguments: { (#offset -> 'ten') } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	response := (error asJRPCResponseWithId: 7) asJRPCJSON.
	errorJson := response at: 'error'.
	data := errorJson at: 'data'.
	violations := data at: 'violations'.
	firstViolation := violations first.
	self assert: (errorJson at: 'code') equals: -32602.
	self assert: (data at: 'toolName') equals: 'package_search'.
	self assert: (firstViolation at: #path) equals: #( 'offset' ).
	self assert: (firstViolation at: #keyword) equals: 'type'.
	self assert: (firstViolation at: #message) equals: 'Value has the wrong JSON type.'
]

{ #category : 'tests' }
MCPToolRequestTest >> testNonNegativeIntegerArgumentClampsValuesAboveMaximum [

	| request |
	request := MCPToolRequest new
		           tool: MCPToolDebugSearch new;
		           arguments: { (#stackLimit -> 51) } asDictionary;
		           yourself.
	self assert: (request nonNegativeIntegerArgumentNamed: 'stackLimit' default: 5 maximum: 50) equals: 50
]

{ #category : 'tests' }
MCPToolRequestTest >> testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings [

	| nested request |
	request := MCPToolRequest tool: MCPToolCreateRepository new arguments: {
			           (#name -> 'Example').
			           (#location -> FileLocator imageDirectory fullName).
			           (#packageNames -> #( ' MCP ' '' 'MCP' 'Other' )) } asDictionary.
	self assert: (request stringCollectionArgumentNamed: 'packageNames') equals: #( 'MCP' 'MCP' 'Other' ).
	self assert: (request uniqueStringCollectionArgumentNamed: 'packageNames') equals: #( 'MCP' 'Other' ).
	self assert: (request stringArgumentNamed: 'missing' default: 'image') equals: 'image'.
	self assert: (request symbolCollectionArgumentNamed: 'packageNames') equals: #( #MCP #MCP #Other ).
	nested := {
		          (#className -> ' MCPToolRequestTest ').
		          (#testMethodName -> ' testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings ') } asDictionary.
	self assert: (request stringArgumentNamed: 'className' in: nested) equals: 'MCPToolRequestTest'.
	self
		assert: (request stringArgumentNamed: 'testMethodName' in: nested)
		equals: 'testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings'
]

{ #category : 'tests' }
MCPToolRequestTest >> testToolRequestClampsArgumentsAboveSchemaMaximumBeforeValidation [

	| request |
	request := MCPToolGetClass new requestFromToolCallArguments: {
		           (#name -> 'Object').
		           (#subclassDepth -> 1000) } asDictionary.
	self
		assert: (request argumentNamed: 'subclassDepth' ifAbsent: [ self fail: 'Expected a normalized depth.' ])
		equals: MCPToolGetClass new maximumSubclassDepth
]

{ #category : 'tests' }
MCPToolRequestTest >> testValidRequestProvidesTypedAccessors [

	| request scope |
	scope := { (#packages -> #( 'MCP' )) } asDictionary.
	request := MCPToolRequest tool: MCPToolSearchClasses new arguments: {
		           (#scope -> scope).
		           (#offset -> 3) } asDictionary.
	self assert: (request nonNegativeIntegerArgumentNamed: 'offset' default: 100) equals: 3.
	self assert: (request stringCollectionArgumentNamed: 'packages' in: scope) equals: #( 'MCP' ).
	self assert: (request stringArgumentNamed: 'missing') isNil.
	self assert: (request booleanArgumentNamed: 'missing' default: false) equals: false
]

