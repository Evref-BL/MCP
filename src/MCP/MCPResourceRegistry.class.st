"
Instance-scoped catalog of MCP resources, keyed by URI.

Every registered resource is listed: resources have no advertising split, because a client decides for itself which of them to put in front of a model. Holding, discovery and rediscovery come from MCPRegistry.
"
Class {
	#name : 'MCPResourceRegistry',
	#superclass : 'MCPRegistry',
	#category : 'MCP-Resources',
	#package : 'MCP',
	#tag : 'Resources'
}

{ #category : 'resources' }
MCPResourceRegistry >> addResource: aResourceOrResourceClass [

	^ self add: aResourceOrResourceClass
]

{ #category : 'resources' }
MCPResourceRegistry >> addResources: resourcesOrResourceClasses [

	^ self addAll: resourcesOrResourceClasses
]

{ #category : 'testing' }
MCPResourceRegistry >> includesResourceAt: aUri [

	^ self includesKey: aUri
]

{ #category : 'entries' }
MCPResourceRegistry >> keyFor: aResource [

	^ aResource uri
]

{ #category : 'entries' }
MCPResourceRegistry >> registeredClass [

	^ MCPResource
]

{ #category : 'resources' }
MCPResourceRegistry >> removeResourceAt: aUri [

	self removeKey: aUri
]

{ #category : 'resources' }
MCPResourceRegistry >> resourceAt: aUri ifAbsent: absentBlock [
	"Answer the resource for aUri, from the catalog or from the first template that recognises it."

	^ self
		  at: aUri
		  ifAbsent: [
			  self resourceTemplates
				  detect: [ :each | (each resourceForUri: aUri) isNotNil ]
				  ifFound: [ :template | template resourceForUri: aUri ]
				  ifNone: absentBlock ]
]

{ #category : 'resources' }
MCPResourceRegistry >> resourceTemplates [
	"Templates are resources that stand for a family of URIs rather than one, so they list separately."

	^ (self entries select: [ :each | each isResourceTemplate ]) asArray
]

{ #category : 'resources' }
MCPResourceRegistry >> resourceUris [

	^ self keys
]

{ #category : 'resources' }
MCPResourceRegistry >> resources [
	"The concrete resources, which is what resources/list answers. Templates list through resources/templates/list instead."

	^ (self entries reject: [ :each | each isResourceTemplate ]) asArray
]
