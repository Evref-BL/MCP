"
MCP protocol structure for one message of a prompt.

A message carries a role, user or assistant, and one content block. Text is the common case; the content block may be any MCPStructureContentBlock.
"
Class {
	#name : 'MCPStructurePromptMessage',
	#superclass : 'Object',
	#instVars : [
		'role',
		'content'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructurePromptMessage class >> role: aRole content: aContentBlock [

	^ self new
		  role: aRole;
		  content: aContentBlock;
		  yourself
]

{ #category : 'instance creation' }
MCPStructurePromptMessage class >> userText: aString [

	^ self role: 'user' content: (MCPStructureTextContent text: aString)
]

{ #category : 'converting' }
MCPStructurePromptMessage >> asJRPCJSON [

	^ {
		  (#role -> self role asJRPCJSON).
		  (#content -> self content asJRPCJSON) } asDictionary
]

{ #category : 'accessing' }
MCPStructurePromptMessage >> content [

	^ content
]

{ #category : 'accessing' }
MCPStructurePromptMessage >> content: anObject [

	content := anObject
]

{ #category : 'accessing' }
MCPStructurePromptMessage >> role [

	^ role
]

{ #category : 'accessing' }
MCPStructurePromptMessage >> role: anObject [

	role := anObject
]
