"
Abstract MCP resource template: a family of resources named by an RFC 6570 URI template.

A template lists through resources/templates/list and never answers contents of its own. Reading one of its URIs goes through `resourceForUri:`, which answers a concrete MCPResource when the URI is the template's shape and nil when it is not.

Subclasses answer a `resourceUriTemplate` and implement `resourceForUri:`.
"
Class {
	#name : 'MCPResourceTemplate',
	#superclass : 'MCPResource',
	#category : 'MCP-Resources',
	#package : 'MCP',
	#tag : 'Resources'
}

{ #category : 'testing' }
MCPResourceTemplate class >> isAbstract [

	^ self = MCPResourceTemplate
]

{ #category : 'metadata' }
MCPResourceTemplate class >> resourceUri [
	"A template is identified by its template string, which is also its key in the registry."

	^ self resourceUriTemplate
]

{ #category : 'metadata' }
MCPResourceTemplate class >> resourceUriTemplate [

	^ self subclassResponsibility
]

{ #category : 'converting' }
MCPResourceTemplate >> asJRPCJSON [
	"Templates carry uriTemplate where a resource carries uri."

	| dictionary |
	dictionary := super asJRPCJSON.
	dictionary removeKey: #uri ifAbsent: [ nil ].
	dictionary at: #uriTemplate put: self uriTemplate asJRPCJSON.
	^ dictionary
]

{ #category : 'completing' }
MCPResourceTemplate >> completionsFor: aVariableName value: aPrefix context: aContextDictionary [
	"Answer the values completion/complete should suggest for one of my URI variables, given what the user has typed so far and the variables already settled. Answering none is fine: a template owes no completions."

	^ #(  )
]

{ #category : 'testing' }
MCPResourceTemplate >> isResourceTemplate [

	^ true
]

{ #category : 'reading' }
MCPResourceTemplate >> readContents [

	^ Error signal: 'A resource template is read through one of its URIs, not directly: ' , self uriTemplate
]

{ #category : 'resolving' }
MCPResourceTemplate >> resourceForUri: aUri [
	"Answer the resource aUri names within this template, or nil when the URI is not this template's shape."

	^ self subclassResponsibility
]

{ #category : 'metadata' }
MCPResourceTemplate >> uriTemplate [

	^ self class resourceUriTemplate
]
