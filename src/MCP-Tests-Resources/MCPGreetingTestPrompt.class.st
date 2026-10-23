"
Prompt fixture: greets a name, with an optional greeting word.

It lives outside the MCP package so it does not register itself into every server.
"
Class {
	#name : 'MCPGreetingTestPrompt',
	#superclass : 'MCPPrompt',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'metadata' }
MCPGreetingTestPrompt class >> promptName [

	^ 'greet'
]

{ #category : 'metadata' }
MCPGreetingTestPrompt >> arguments [

	^ {
		  (MCPStructurePromptArgument name: 'who' description: 'Who to greet.' required: true).
		  (MCPStructurePromptArgument name: 'greeting' description: 'The greeting word.' required: false) }
]

{ #category : 'completing' }
MCPGreetingTestPrompt >> completionsFor: anArgumentName value: aPrefix context: aContextDictionary [

	anArgumentName = 'greeting' ifFalse: [ ^ #(  ) ].
	^ #( 'Hello' 'Goodbye' 'Good morning' ) select: [ :each | each beginsWith: aPrefix ]
]

{ #category : 'metadata' }
MCPGreetingTestPrompt >> description [

	^ 'Greets someone.'
]

{ #category : 'building' }
MCPGreetingTestPrompt >> messagesFor: anArgumentDictionary [

	| greeting |
	greeting := anArgumentDictionary at: 'greeting' ifAbsent: [ 'Hello' ].
	^ self userMessage: greeting , ', ' , (anArgumentDictionary at: 'who') , '!'
]

{ #category : 'metadata' }
MCPGreetingTestPrompt >> title [

	^ 'Greet Someone'
]
