"
Tests the resource half of the protocol: listing, reading, templates, and the capability that follows from what the server holds.
"
Class {
	#name : 'MCPResourceTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'tests' }
MCPResourceTest >> testCapabilitiesLeaveOutResourcesWhenThereAreNone [
	"A capability for an empty catalog promises methods that would answer nothing."

	| capabilities |
	capabilities := (self mcpWithoutObservabilityExport
		                 onlyResources: #(  );
		                 yourself) advertisedCapabilities asJRPCJSON.
	self deny: (capabilities includesKey: #resources).
	self assert: (capabilities includesKey: #tools)
]

{ #category : 'tests' }
MCPResourceTest >> testCapabilitiesSayNothingTheTransportCannotDo [
	"The transport answers GET with 405 and has no stream, so neither subscribe nor listChanged may be declared."

	| resources |
	resources := self mcpWithoutObservabilityExport advertisedCapabilities asJRPCJSON at: #resources.
	self deny: (resources includesKey: #subscribe).
	self deny: (resources includesKey: #listChanged)
]

{ #category : 'tests' }
MCPResourceTest >> testImageMetadataResourceReadsAsJSON [

	| contents parsed |
	contents := (self mcpWithoutObservabilityExport rpcResourceRead: MCPImageMetadataResource resourceUri) at: #contents.
	self assert: contents size equals: 1.
	self assert: (contents first at: #mimeType) equals: 'application/json'.
	self assert: (contents first at: #uri) equals: MCPImageMetadataResource resourceUri.
	parsed := STONJSON fromString: (contents first at: #text).
	self assert: (parsed at: 'runtimeVersion') equals: SystemVersion current version.
	self assert: (parsed at: 'majorVersion') equals: SystemVersion current major
]

{ #category : 'tests' }
MCPResourceTest >> testReadingAnUnknownUriAnswersResourceNotFound [

	| raised |
	raised := [
	          self mcpWithoutObservabilityExport rpcResourceRead: 'pharo://nothing/here'.
	          nil ] on: MCPResourceNotFound do: [ :error | error ].
	self assert: raised uri equals: 'pharo://nothing/here'.
	self assert: MCPResourceNotFound errorCode equals: -32002
]

{ #category : 'tests' }
MCPResourceTest >> testResourcesListAnswersRegisteredResources [

	| uris |
	uris := (self mcpWithoutObservabilityExport rpcResourcesList at: #resources) collect: [ :each | each at: #uri ].
	self assert: (uris includes: MCPImageMetadataResource resourceUri)
]

{ #category : 'tests' }
MCPResourceTest >> testResourcesListEntriesCarryTheRequiredFields [
	"Only uri and name are required of a resource, and nothing optional may be sent as null."

	(self mcpWithoutObservabilityExport rpcResourcesList at: #resources) do: [ :each |
			self assert: (each includesKey: #uri).
			self assert: (each includesKey: #name).
			self deny: (each values includes: nil) ]
]

{ #category : 'tests' }
MCPResourceTest >> testTemplatesListSeparatelyFromResources [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp addResource: MCPResourceTemplateTestFixture.
	self deny:
		((mcp rpcResourcesList at: #resources) anySatisfy: [ :each | (each at: #uri) = MCPResourceTemplateTestFixture resourceUriTemplate ]).
	self assert: ((mcp rpcResourcesTemplateList at: #resourceTemplates) anySatisfy: [ :each |
			 (each at: #uriTemplate) = MCPResourceTemplateTestFixture resourceUriTemplate ])
]

{ #category : 'tests' }
MCPResourceTest >> testTemplateResolvesOneOfItsUris [

	| mcp contents |
	mcp := self mcpWithoutObservabilityExport.
	mcp addResource: MCPResourceTemplateTestFixture.
	contents := (mcp rpcResourceRead: 'pharo://greeting/world') at: #contents.
	self assert: (contents first at: #text) equals: 'Hello, world!'
]

{ #category : 'tests' }
MCPResourceTest >> testTemplateRefusesAUriOfAnotherShape [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp addResource: MCPResourceTemplateTestFixture.
	self should: [ mcp rpcResourceRead: 'pharo://farewell/world' ] raise: MCPResourceNotFound
]
