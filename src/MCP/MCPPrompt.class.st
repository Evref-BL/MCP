"
Abstract MCP prompt: a named message template a user invokes.

Prompts are user-controlled where tools are model-controlled. A client typically surfaces them as slash commands, so a prompt is something a person reaches for deliberately, not something a model calls on its own.

Subclasses answer a `promptName`, which is also their key in the registry, declare the arguments they take, and build their messages from the arguments supplied. Only `name` is required of a prompt; `title`, `description` and `arguments` are there for clients that display a picker.

Concrete subclasses in the MCP package register themselves, the way tools and resources do. Override `shouldAutoRegister` to opt a prompt of your own in.
"
Class {
	#name : 'MCPPrompt',
	#superclass : 'Object',
	#category : 'MCP-Prompts',
	#package : 'MCP',
	#tag : 'Prompts'
}

{ #category : 'querying' }
MCPPrompt class >> concreteSubclasses [

	^ self allSubclasses reject: [ :each | each isAbstract ]
]

{ #category : 'testing' }
MCPPrompt class >> isAbstract [

	^ self = MCPPrompt
]

{ #category : 'testing' }
MCPPrompt class >> isBuiltIn [

	^ self package = MCPPrompt package
]

{ #category : 'instance creation' }
MCPPrompt class >> newForRegistry: aRegistry [

	^ self new
]

{ #category : 'metadata' }
MCPPrompt class >> promptName [

	^ self subclassResponsibility
]

{ #category : 'testing' }
MCPPrompt class >> shouldAutoRegister [

	^ self isBuiltIn
]

{ #category : 'metadata' }
MCPPrompt >> arguments [
	"Answer the arguments this prompt takes, as MCPStructurePromptArgument instances."

	^ #(  )
]

{ #category : 'converting' }
MCPPrompt >> asJRPCJSON [
	"The descriptor prompts/list answers. Optional fields are left out rather than sent as null."

	| dictionary |
	dictionary := Dictionary new
		              at: #name put: self name asJRPCJSON;
		              yourself.
	self title ifNotNil: [ :value | dictionary at: #title put: value asJRPCJSON ].
	self description ifNotNil: [ :value | dictionary at: #description put: value asJRPCJSON ].
	self arguments ifNotEmpty: [ :value | dictionary at: #arguments put: (value collect: [ :each | each asJRPCJSON ]) ].
	^ dictionary
]

{ #category : 'completing' }
MCPPrompt >> completionsFor: anArgumentName value: aPrefix context: aContextDictionary [
	"Answer the values completion/complete should suggest for one of my arguments, given what the user has typed so far and the arguments already settled. Answering none is fine: a prompt owes no completions."

	^ #(  )
]

{ #category : 'metadata' }
MCPPrompt >> description [

	^ nil
]

{ #category : 'building' }
MCPPrompt >> messagesFor: anArgumentDictionary [
	"Answer the messages prompts/get answers, as an array of MCPStructurePromptMessage."

	^ self subclassResponsibility
]

{ #category : 'metadata' }
MCPPrompt >> name [

	^ self class promptName
]

{ #category : 'metadata' }
MCPPrompt >> title [

	^ nil
]

{ #category : 'building' }
MCPPrompt >> userMessage: aString [
	"The common case: one message from the user."

	^ { (MCPStructurePromptMessage userText: aString) }
]

{ #category : 'validating' }
MCPPrompt >> validateArguments: anArgumentDictionary [
	"A missing required argument is the caller's mistake, and the spec answers it as invalid params."

	| missing |
	missing := (self arguments select: [ :each | each isRequired ] thenCollect: [ :each | each name ]) reject: [ :each |
		           (anArgumentDictionary at: each ifAbsent: [ nil ]) isNotNil ].
	missing ifNotEmpty: [ MCPMissingPromptArgument signalForPrompt: self named: missing asArray ]
]
