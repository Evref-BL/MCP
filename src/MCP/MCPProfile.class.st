"
An MCP profile declares the server capabilities a server instance should expose. It currently configures the tool registry and is intended to grow with resource and prompt registries.
"
Class {
	#name : 'MCPProfile',
	#superclass : 'Object',
	#instVars : [
		'toolClasses',
		'staticToolClasses'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'instance creation' }
MCPProfile class >> default [

	^ self new
]

{ #category : 'instance creation' }
MCPProfile class >> empty [

	^ self tools: #(  )
]

{ #category : 'instance creation' }
MCPProfile class >> tools: toolClasses [

	^ self tools: toolClasses static: toolClasses
]

{ #category : 'instance creation' }
MCPProfile class >> tools: toolClasses static: staticToolClasses [

	^ self new
		  toolClasses: toolClasses;
		  staticToolClasses: staticToolClasses;
		  yourself
]

{ #category : 'applying' }
MCPProfile >> applyTo: anMCP [

	anMCP toolRegistry: self toolRegistry
]

{ #category : 'private' }
MCPProfile >> configuredToolRegistry [

	| registry |
	registry := MCPToolRegistry empty.
	registry registerToolClasses: self toolClasses.
	self staticToolClasses ifNotNil: [ registry staticToolNames: (self staticToolClasses collect: [ :each | each toolName ]) ].
	^ registry
]

{ #category : 'accessing' }
MCPProfile >> staticToolClasses [

	^ staticToolClasses
]

{ #category : 'accessing' }
MCPProfile >> staticToolClasses: aCollection [

	staticToolClasses := aCollection
]

{ #category : 'accessing' }
MCPProfile >> toolClasses [

	^ toolClasses
]

{ #category : 'accessing' }
MCPProfile >> toolClasses: aCollection [

	toolClasses := aCollection
]

{ #category : 'accessing' }
MCPProfile >> toolRegistry [

	self usesDefaultTools ifTrue: [ ^ MCPToolRegistry default ].
	^ self configuredToolRegistry
]

{ #category : 'testing' }
MCPProfile >> usesDefaultTools [

	^ self toolClasses isNil
]
