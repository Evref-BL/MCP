"
Resource template fixture: pharo://greeting/{name} answers a greeting for the name in the URI.

It lives outside the MCP package so it does not register itself into every server.
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

{ #category : 'metadata' }
MCPResourceTemplateTestFixture class >> uriPrefix [

	^ 'pharo://greeting/'
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
