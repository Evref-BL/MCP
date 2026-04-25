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
	request := MCPToolRequest
		           tool: MCPToolEvaluate new
		           arguments: { ('code' -> '1 + 1') } asDictionary.
	self assert: (request hasArgumentNamed: 'code').
	self assert: (request hasArgumentNamed: #code).
	self deny: (request hasArgumentNamed: 'missing')
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidRequestRaisesInvalidParameters [

	self
		should: [
			MCPToolRequest
				tool: MCPToolFindClasses new
				arguments: { (#caseSensitive -> 'true') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidRequestRaisesToolInputErrorWithViolations [

	| error violation |
	[
	MCPToolRequest
		tool: MCPToolFindClasses new
		arguments: { (#caseSensitive -> 'true') } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	self assert: error isNotNil.
	self assert: error toolName equals: 'find-classes'.
	self assert: error violations size equals: 1.
	violation := error violations first.
	self assert: violation path equals: #( 'caseSensitive' ).
	self assert: violation keyword equals: 'type'.
	self assert: violation expected equals: 'boolean'.
	self assert: violation actual equals: 'string'
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidToolInputErrorResponseIncludesViolations [

	| data error errorJson firstViolation response violations |
	[
	MCPToolRequest
		tool: MCPToolFindClasses new
		arguments: { (#caseSensitive -> 'true') } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	response := (error asJRPCResponseWithId: 7) asJRPCJSON.
	errorJson := response at: 'error'.
	data := errorJson at: 'data'.
	violations := data at: 'violations'.
	firstViolation := violations first.
	self assert: (errorJson at: 'code') equals: -32602.
	self assert: (data at: 'toolName') equals: 'find-classes'.
	self assert: (firstViolation at: #path) equals: #( 'caseSensitive' ).
	self assert: (firstViolation at: #keyword) equals: 'type'.
	self
		assert: (firstViolation at: #message)
		equals: 'Value has the wrong JSON type.'
]

{ #category : 'tests' }
MCPToolRequestTest >> testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings [

	| nested request |
	request := MCPToolRequest tool: MCPToolFindClasses new arguments: {
			           (#packageNames -> #( ' MCP ' '' 'MCP' )).
			           (#filterTargets -> #( 'class' 'package' 'class' )) }
			           asDictionary.
	self
		assert: (request stringCollectionArgumentNamed: 'packageNames')
		equals: #( 'MCP' 'MCP' ).
	self
		assert:
		(request uniqueStringCollectionArgumentNamed: 'filterTargets')
		equals: #( 'class' 'package' ).
	self
		assert: (request stringArgumentNamed: 'missing' default: 'image')
		equals: 'image'.
	self
		assert: (request symbolCollectionArgumentNamed: 'packageNames')
		equals: #( #MCP #MCP ).
	nested := {
		          (#className -> ' MCPToolRequestTest ').
		          (#testMethodName
		           ->
		           ' testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings ') }
		          asDictionary.
	self
		assert: (request stringArgumentNamed: 'className' in: nested)
		equals: 'MCPToolRequestTest'.
	self
		assert: (request stringArgumentNamed: 'testMethodName' in: nested)
		equals:
		'testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings'
]

{ #category : 'tests' }
MCPToolRequestTest >> testValidRequestProvidesTypedAccessors [

	| request |
	request := MCPToolRequest tool: MCPToolFindClasses new arguments: {
			           (#packageNames -> #( 'MCP' )).
			           (#caseSensitive -> true).
			           (#limit -> 3) } asDictionary.
	self assert:
		(request booleanArgumentNamed: 'caseSensitive' default: false).
	self
		assert:
		(request nonNegativeIntegerArgumentNamed: 'limit' default: 100)
		equals: 3.
	self
		assert: (request stringCollectionArgumentNamed: 'packageNames')
		equals: #( 'MCP' ).
	self assert: (request stringArgumentNamed: 'missing') isNil.
	self
		assert: (request booleanArgumentNamed: 'missing' default: false)
		equals: false
]
