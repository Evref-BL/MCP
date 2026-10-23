"
Instance-scoped catalog of MCP prompts, keyed by name.

Every registered prompt is listed: prompts have no advertising split, because a person chooses which one to invoke. Holding, discovery and rediscovery come from MCPRegistry.
"
Class {
	#name : 'MCPPromptRegistry',
	#superclass : 'MCPRegistry',
	#category : 'MCP-Prompts',
	#package : 'MCP',
	#tag : 'Prompts'
}

{ #category : 'prompts' }
MCPPromptRegistry >> addPrompt: aPromptOrPromptClass [

	^ self add: aPromptOrPromptClass
]

{ #category : 'prompts' }
MCPPromptRegistry >> addPrompts: promptsOrPromptClasses [

	^ self addAll: promptsOrPromptClasses
]

{ #category : 'testing' }
MCPPromptRegistry >> includesPromptNamed: aName [

	^ self includesKey: aName
]

{ #category : 'entries' }
MCPPromptRegistry >> keyFor: aPrompt [

	^ aPrompt name
]

{ #category : 'prompts' }
MCPPromptRegistry >> promptNamed: aName ifAbsent: absentBlock [

	^ self at: aName ifAbsent: absentBlock
]

{ #category : 'prompts' }
MCPPromptRegistry >> promptNames [

	^ self keys
]

{ #category : 'prompts' }
MCPPromptRegistry >> prompts [

	^ self entries
]

{ #category : 'entries' }
MCPPromptRegistry >> registeredClass [

	^ MCPPrompt
]

{ #category : 'prompts' }
MCPPromptRegistry >> removePromptNamed: aName [

	self removeKey: aName
]
