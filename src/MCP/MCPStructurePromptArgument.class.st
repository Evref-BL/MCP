"
MCP protocol structure for one argument a prompt accepts.

Only the name is required; a description helps a client that renders a form, and required says whether prompts/get may be called without it.
"
Class {
	#name : 'MCPStructurePromptArgument',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'required'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructurePromptArgument class >> name: aName description: aDescription required: aBoolean [

	^ self new
		  name: aName;
		  description: aDescription;
		  required: aBoolean;
		  yourself
]

{ #category : 'converting' }
MCPStructurePromptArgument >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new
		              at: #name put: self name asJRPCJSON;
		              yourself.
	self description ifNotNil: [ :value | dictionary at: #description put: value asJRPCJSON ].
	self required ifNotNil: [ :value | dictionary at: #required put: value asJRPCJSON ].
	^ dictionary
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> description [

	^ description
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> description: anObject [

	description := anObject
]

{ #category : 'testing' }
MCPStructurePromptArgument >> isRequired [

	^ self required = true
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> name [

	^ name
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> required [

	^ required
]

{ #category : 'accessing' }
MCPStructurePromptArgument >> required: anObject [

	required := anObject
]
