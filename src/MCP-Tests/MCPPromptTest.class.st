"
Tests the prompt half of the protocol: listing, getting, argument validation, and the capability that follows from what the server holds.
"
Class {
	#name : 'MCPPromptTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPPromptTest >> serverWithGreeting [

	^ self mcpWithoutObservabilityExport
		  onlyPrompts: { MCPGreetingTestPrompt };
		  yourself
]

{ #category : 'tests' }
MCPPromptTest >> testCapabilitiesLeaveOutPromptsWhenThereAreNone [
	"A stock server ships no prompts, so it must not claim the domain."

	| capabilities |
	capabilities := self mcpWithoutObservabilityExport advertisedCapabilities asJRPCJSON.
	self deny: (capabilities includesKey: #prompts).
	self assert: (capabilities includesKey: #tools)
]

{ #category : 'tests' }
MCPPromptTest >> testCapabilitiesNamePromptsOnceOneIsRegistered [

	| capabilities |
	capabilities := self serverWithGreeting advertisedCapabilities asJRPCJSON.
	self assert: (capabilities includesKey: #prompts).
	self assert: ((capabilities at: #prompts) at: #listChanged)
]

{ #category : 'tests' }
MCPPromptTest >> testGettingAPromptAnswersItsMessages [

	| result |
	result := self serverWithGreeting rpcPromptGet: 'greet' arguments: { ('who' -> 'world') } asDictionary.
	self assert: (result at: #description) equals: 'Greets someone.'.
	self assert: (result at: #messages) size equals: 1.
	self assert: ((result at: #messages) first at: #role) equals: 'user'.
	self assert: (((result at: #messages) first at: #content) at: #text) equals: 'Hello, world!'.
	self assert: (((result at: #messages) first at: #content) at: #type) equals: 'text'
]

{ #category : 'tests' }
MCPPromptTest >> testGettingAPromptUsesSuppliedOptionalArguments [

	| result |
	result := self serverWithGreeting
		          rpcPromptGet: 'greet'
		          arguments: {
				          ('who' -> 'world').
				          ('greeting' -> 'Goodbye') } asDictionary.
	self assert: (((result at: #messages) first at: #content) at: #text) equals: 'Goodbye, world!'
]

{ #category : 'tests' }
MCPPromptTest >> testOmittingARequiredArgumentIsInvalidParams [

	| raised |
	raised := [
	          self serverWithGreeting rpcPromptGet: 'greet' arguments: Dictionary new.
	          nil ] on: MCPMissingPromptArgument do: [ :error | error ].
	self assert: raised missingArguments equals: #( 'who' ).
	self assert: (raised isKindOf: JRPCInvalidParameters)
]

{ #category : 'tests' }
MCPPromptTest >> testPromptsGetReturnsInvalidParamsWhenPromptIsUnknown [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"prompts/get","params":{"name":"missing"}}'.
	self assert: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring: '"message":"Invalid method parameter(s)."').
	self assert: (response includesSubstring: '"prompt":"missing"')
]

{ #category : 'tests' }
MCPPromptTest >> testPromptsListCarriesTheDeclaredArguments [

	| prompt |
	prompt := (self serverWithGreeting rpcPromptsList at: #prompts) first.
	self assert: (prompt at: #name) equals: 'greet'.
	self assert: (prompt at: #title) equals: 'Greet Someone'.
	self assert: ((prompt at: #arguments) collect: [ :each | each at: #name ]) equals: #( 'who' 'greeting' ).
	self assert: ((prompt at: #arguments) first at: #required).
	self deny: ((prompt at: #arguments) second at: #required)
]

{ #category : 'tests' }
MCPPromptTest >> testPromptsListReturnsEmptyPromptList [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"prompts/list"}'.
	self assert: (response includesSubstring: '"result":{"prompts":[]}')
]
