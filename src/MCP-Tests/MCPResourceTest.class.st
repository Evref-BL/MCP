"
Tests the resource half of the protocol: listing, reading, templates, and the capability that follows from what the server holds.
"
Class {
	#name : 'MCPResourceTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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
MCPResourceTest >> testResourcesListAnswersTheRegisteredResources [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/list"}'.
	self assert: (response includesSubstring: '"resources":').
	self assert: (response includesSubstring: MCPImageMetadataResource resourceUri)
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
MCPResourceTest >> testResourcesReadAnswersResourceNotFoundWhenTheUriIsUnknown [
	"The spec gives resource-not-found its own code rather than folding it into invalid params, and asks for the URI in the error data."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":"pharo://missing"}}'.
	self assert: (response includesSubstring: '"code":-32002').
	self assert: (response includesSubstring: '"message":"Resource not found"').
	self assert: (response includesSubstring: '"uri":"pharo://missing"')
]

{ #category : 'tests' }
MCPResourceTest >> testResourcesTemplatesListReturnsEmptyTemplateList [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/templates/list"}'.
	self assert: (response includesSubstring: '"result":{"resourceTemplates":[]}')
]

{ #category : 'tests' }
MCPResourceTest >> testTemplateRefusesAUriOfAnotherShape [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp addResource: MCPResourceTemplateTestFixture.
	self should: [ mcp rpcResourceRead: 'pharo://farewell/world' ] raise: MCPResourceNotFound
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
MCPResourceTest >> testTemplatesListSeparatelyFromResources [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp addResource: MCPResourceTemplateTestFixture.
	self deny:
		((mcp rpcResourcesList at: #resources) anySatisfy: [ :each | (each at: #uri) = MCPResourceTemplateTestFixture resourceUriTemplate ]).
	self assert: ((mcp rpcResourcesTemplateList at: #resourceTemplates) anySatisfy: [ :each |
			 (each at: #uriTemplate) = MCPResourceTemplateTestFixture resourceUriTemplate ])
]
