"
Tests MCPToolRequest validation and typed argument access.
"
Class {
	#name : 'MCPToolRequestTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPToolRequestTest >> testANameTwoArgumentsDeclareWithDifferentDefaultsHasNoDefaultInsideThem [
	"An accessor that reads inside an argument is given the object, not the argument it came from, so it answers no default for a name two arguments declare differently rather than the other argument's."

	| request |
	request := MCPToolRequest new.
	request rememberDefaultsIn: (STONJSON fromString: '{"properties": {
		"render": {"type": "object", "properties": {"mode": {"type": "string", "default": "fast"}, "quality": {"type": "string", "default": "high"}}},
		"export": {"type": "array", "items": {"type": "object", "properties": {"mode": {"type": "string", "default": "safe"}}}}}}').
	self assert: (request argumentOrDefaultNamed: 'mode' in: Dictionary new) isNil.
	self assert: (request argumentOrDefaultNamed: 'quality' in: Dictionary new) equals: 'high'
]

{ #category : 'tests' }
MCPToolRequestTest >> testASuppliedArgumentWinsOverItsSchemaDefault [

	| request |
	request := MCPToolEvaluate new requestFromToolCallArguments: {
			           (#code -> '3 + 4').
			           (#timeoutSeconds -> 7) } asDictionary.
	self assert: (request integerArgumentOrDefaultNamed: 'timeoutSeconds') equals: 7.
	request := MCPToolGetMethod new requestFromToolCallArguments: {
			           (#class -> 'Object').
			           (#selector -> 'yourself').
			           (#includeVariableDetails -> true) } asDictionary.
	self assert: (request booleanArgumentOrDefaultNamed: 'includeVariableDetails')
]

{ #category : 'tests' }
MCPToolRequestTest >> testAnArgumentLeftOutAnswersTheDefaultItsSchemaDeclares [

	| request |
	request := MCPToolEvaluate new requestFromToolCallArguments: { (#code -> '3 + 4') } asDictionary.
	self assert: (request integerArgumentOrDefaultNamed: 'timeoutSeconds') equals: MCPToolEvaluate new defaultTimeoutSeconds.
	self deny: (request hasArgumentNamed: 'timeoutSeconds').
	request := MCPToolGetMethod new requestFromToolCallArguments: {
			           (#class -> 'Object').
			           (#selector -> 'yourself') } asDictionary.
	self deny: (request booleanArgumentOrDefaultNamed: 'includeVariableDetails').
	request := MCPToolCreateClass new requestFromToolCallArguments: {
			           (#name -> 'Example').
			           (#package -> 'Example-Package').
			           (#superclass -> ' ') } asDictionary.
	self assert: (request stringArgumentOrDefaultNamed: 'superclass') equals: 'Object'.
	request := MCPToolSearchMethodSource new requestFromToolCallArguments: {
			           (#query -> 'yourself').
			           (#scope -> { (#classes -> #( 'Object' )) } asDictionary) } asDictionary.
	self assert: (request argumentOrDefaultNamed: 'side' in: (request argumentNamed: 'scope' ifAbsent: [ nil ])) equals: 'both'
]

{ #category : 'tests' }
MCPToolRequestTest >> testBlankRequiredArgumentIsRefusedByEveryTool [
	"The mutations always refused a blank required argument. Every other tool read it as nil and failed deep inside Pharo, naming neither the tool nor the argument."

	{
		(MCPToolEvaluate -> { (#code -> '   ') }).
		(MCPToolGetMethod -> {
			 (#class -> 'Object').
			 (#selector -> '   ') }) } do: [ :each |
			| error |
			error := nil.
			[ MCPToolRequest tool: each key new arguments: each value asDictionary ]
				on: MCPInvalidToolInput
				do: [ :signalledError | error := signalledError ].
			self assert: error isNotNil.
			self assert: error violations first keyword equals: 'required'.
			self assert: error violations first expected equals: each value last key asString ]
]

{ #category : 'tests' }
MCPToolRequestTest >> testBlankRequiredArgumentIsRefusedLikeAMissingOne [
	"A blank required argument used to pass validation and reach the image as nil, where it failed deep inside Pharo instead of naming the argument that was wrong."

	| error |
	[
		MCPToolRequest tool: MCPToolCreateClass new arguments: {
				(#name -> 'MCPToolRequestTestGenerated').
				(#superclass -> 'Object').
				(#package -> '   ') } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	self assert: error isNotNil.
	self assert: error toolName equals: 'class_create'.
	self assert: error violations size equals: 1.
	self assert: error violations first keyword equals: 'required'.
	self assert: error violations first expected equals: 'package'
]

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
	self assert: (data at: 'tool') equals: 'package_search'.
	self assert: (firstViolation at: #path) equals: #( 'offset' ).
	self assert: (firstViolation at: #keyword) equals: 'type'.
	self assert: (firstViolation at: #message) equals: 'Value has the wrong JSON type.'
]

{ #category : 'tests' }
MCPToolRequestTest >> testInvalidToolInputSaysEachViolationInWords [

	| error |
	[
		MCPToolRequest tool: MCPToolSearchPackages new arguments: {
				(#offset -> 'ten').
				(#extra -> true) } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	self assert: (error messageText beginsWith: 'Invalid arguments for package_search. ').
	self assert: (error messageText includesSubstring: 'offset must be integer, not string.').
	self assert: (error messageText includesSubstring: 'extra is not accepted here; expected one of ').
	self assert: (error messageText includesSubstring: 'offset, ')
]

{ #category : 'tests' }
MCPToolRequestTest >> testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings [

	| nested request |
	request := MCPToolRequest tool: MCPToolCreateRepository new arguments: {
			           (#repository -> 'Example').
			           (#location -> FileLocator imageDirectory fullName).
			           (#packages -> #( ' MCP ' '' 'MCP' 'Other' )) } asDictionary.
	self assert: (request stringCollectionArgumentNamed: 'packages') equals: #( 'MCP' 'MCP' 'Other' ).
	self assert: (request uniqueStringCollectionArgumentNamed: 'packages') equals: #( 'MCP' 'Other' ).
	self assert: (request stringArgumentNamed: 'missing' default: 'image') equals: 'image'.
	self assert: (request symbolCollectionArgumentNamed: 'packages') equals: #( #MCP #MCP #Other ).
	nested := {
		          (#class -> ' MCPToolRequestTest ').
		          (#testMethod -> ' testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings ') } asDictionary.
	self assert: (request stringArgumentNamed: 'class' in: nested) equals: 'MCPToolRequestTest'.
	self
		assert: (request stringArgumentNamed: 'testMethod' in: nested)
		equals: 'testRequestAccessorsProvideDefaultsUniqueCollectionsSymbolsAndNestedStrings'
]

{ #category : 'tests' }
MCPToolRequestTest >> testToolRequestClampsArgumentsAboveSchemaMaximumBeforeValidation [

	| request |
	request := MCPToolEvaluate new requestFromToolCallArguments: {
			           (#code -> '3 + 4').
			           (#timeoutSeconds -> 100000) } asDictionary.
	self
		assert: (request argumentNamed: 'timeoutSeconds' ifAbsent: [ self fail: 'Expected a normalized timeout.' ])
		equals: MCPToolEvaluate new maximumTimeoutSeconds
]

{ #category : 'tests' }
MCPToolRequestTest >> testUnexpectedArgumentsNameWhatIsAcceptedOnce [
	"Each unexpected argument is named, and the arguments the tool accepts are said once, not once for each."

	| error text first |
	[
		MCPToolRequest tool: MCPToolSearchPackages new arguments: {
				(#extra -> true).
				(#other -> 1).
				(#offset -> 0) } asDictionary ]
		on: MCPInvalidToolInput
		do: [ :signalledError | error := signalledError ].
	text := error messageText.
	first := text indexOfSubCollection: 'expected one of'.
	self assert: first > 0.
	self assert: (text indexOfSubCollection: 'expected one of' startingAt: first + 1) equals: 0.
	self assert: (text includesSubstring: ' are not accepted here; expected one of ').
	self assert: (text includesSubstring: 'extra').
	self assert: (text includesSubstring: 'other')
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
	self assert: (request booleanArgumentOrDefaultNamed: 'missing') equals: false
]
