"
Resource template fixture: pharo://greeting/{name} answers a greeting for the name in the URI.

It answers false to shouldAutoRegister so it does not register itself into every server.
"
Class {
	#name : 'MCPResourceTemplateTestFixture',
	#superclass : 'MCPResourceTemplate',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'metadata' }
MCPResourceTemplateTestFixture class >> resourceName [

	^ 'greeting'
]

{ #category : 'metadata' }
MCPResourceTemplateTestFixture class >> resourceUriTemplate [

	^ 'pharo://greeting/{name}'
]

{ #category : 'testing' }
MCPResourceTemplateTestFixture class >> shouldAutoRegister [
	"A fixture is not a resource anyone asked for, and MCP's default group loads its own tests, so every fixture says so itself rather than relying on the package it sits in."

	^ false
]

{ #category : 'metadata' }
MCPResourceTemplateTestFixture class >> uriPrefix [

	^ 'pharo://greeting/'
]

{ #category : 'completing' }
MCPResourceTemplateTestFixture >> completionsFor: aVariableName value: aPrefix context: aContextDictionary [

	aVariableName = 'name' ifFalse: [ ^ #(  ) ].
	^ #( 'world' 'pharo' 'moon' ) select: [ :each | each beginsWith: aPrefix ]
]

{ #category : 'metadata' }
MCPResourceTemplateTestFixture >> description [

	^ 'Greets the name in the URI.'
]

{ #category : 'resolving' }
MCPResourceTemplateTestFixture >> resourceForUri: aUri [

	| name |
	(aUri beginsWith: self class uriPrefix) ifFalse: [ ^ nil ].
	name := aUri allButFirst: self class uriPrefix size.
	name ifEmpty: [ ^ nil ].
	^ MCPGreetingTestResource name: name
]
