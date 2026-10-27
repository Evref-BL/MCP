"
Tests completion/complete: the two reference types, the hundred-value cap, and the capability that follows from having something to complete.
"
Class {
	#name : 'MCPCompletionTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPCompletionTest >> promptReference [

	^ { (#type -> 'ref/prompt') . (#name -> MCPGreetingTestPrompt promptName) } asDictionary
]

{ #category : 'private' }
MCPCompletionTest >> serverWithCompletableReferences [

	^ self mcpWithoutObservabilityExport
		  onlyPrompts: { MCPGreetingTestPrompt };
		  addResource: MCPResourceTemplateTestFixture;
		  yourself
]

{ #category : 'private' }
MCPCompletionTest >> templateReference [

	^ { (#type -> 'ref/resource') . (#uri -> MCPResourceTemplateTestFixture resourceUriTemplate) } asDictionary
]

{ #category : 'tests' }
MCPCompletionTest >> testCapabilitiesLeaveOutCompletionsWithNothingToComplete [
	"A stock server has no prompts and no templates, so completion/complete could only ever answer an error."

	self deny: (self mcpWithoutObservabilityExport advertisedCapabilities asJRPCJSON includesKey: #completions)
]

{ #category : 'tests' }
MCPCompletionTest >> testCapabilitiesNameCompletionsOnceSomethingCanBeCompleted [

	| capabilities |
	capabilities := self serverWithCompletableReferences advertisedCapabilities asJRPCJSON.
	self assert: (capabilities includesKey: #completions).
	self assert: (capabilities at: #completions) equals: Dictionary new
]

{ #category : 'tests' }
MCPCompletionTest >> testCompletingAPromptArgumentFiltersOnWhatIsTyped [

	| completion |
	completion := (self serverWithCompletableReferences
		               rpcCompletionComplete: self promptReference
		               argument: { (#name -> 'greeting') . (#value -> 'Goo') } asDictionary
		               context: nil) at: #completion.
	self assert: (completion at: #values) equals: #( 'Goodbye' 'Good morning' ).
	self assert: (completion at: #total) equals: 2.
	self deny: (completion at: #hasMore)
]

{ #category : 'tests' }
MCPCompletionTest >> testCompletingAResourceTemplateVariable [

	| completion |
	completion := (self serverWithCompletableReferences
		               rpcCompletionComplete: self templateReference
		               argument: { (#name -> 'name') . (#value -> '') } asDictionary
		               context: nil) at: #completion.
	self assert: (completion at: #values) equals: #( 'world' 'pharo' 'moon' )
]

{ #category : 'tests' }
MCPCompletionTest >> testCompletingAnArgumentNobodyCompletesAnswersNothing [

	| completion |
	completion := (self serverWithCompletableReferences
		               rpcCompletionComplete: self promptReference
		               argument: { (#name -> 'who') . (#value -> '') } asDictionary
		               context: nil) at: #completion.
	self assert: (completion at: #values) isEmpty.
	self assert: (completion at: #total) equals: 0
]

{ #category : 'tests' }
MCPCompletionTest >> testCompletingAnUnknownPromptIsInvalidParams [

	| raised |
	raised := [
	          self serverWithCompletableReferences
		          rpcCompletionComplete: { (#type -> 'ref/prompt') . (#name -> 'nope') } asDictionary
		          argument: { (#name -> 'who') . (#value -> '') } asDictionary
		          context: nil.
	          nil ] on: MCPUnknownCompletionReference do: [ :error | error ].
	self assert: (raised isKindOf: JRPCInvalidParameters)
]

{ #category : 'tests' }
MCPCompletionTest >> testCompletingAnUnknownReferenceTypeIsInvalidParams [

	| raised |
	raised := [
	          self serverWithCompletableReferences
		          rpcCompletionComplete: { (#type -> 'ref/nonsense') } asDictionary
		          argument: { (#name -> 'who') . (#value -> '') } asDictionary
		          context: nil.
	          nil ] on: MCPUnknownCompletionReference do: [ :error | error ].
	self assert: (raised isKindOf: JRPCInvalidParameters)
]

{ #category : 'tests' }
MCPCompletionTest >> testSuggestionsAreCappedAtAHundred [
	"The spec allows a hundred values per response, so a longer list is cut and says so while total keeps the real count."

	| completion |
	completion := (MCPStructureCompletion values: ((1 to: 150) collect: [ :each | each printString ])) asJRPCJSON.
	self assert: (completion at: #values) size equals: 100.
	self assert: (completion at: #total) equals: 150.
	self assert: (completion at: #hasMore)
]
