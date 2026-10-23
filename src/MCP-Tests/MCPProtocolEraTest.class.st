"
Tests the two eras this server answers.

A legacy request opens with initialize and names no version of its own. A modern request declares its protocol version in _meta on every call, and is refused when the server does not implement that version.
"
Class {
	#name : 'MCPProtocolEraTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPProtocolEraTest >> handleJSON: aJSONString [

	^ self mcpWithoutObservabilityExport server messageProcessor handleJSON: aJSONString
]

{ #category : 'private' }
MCPProtocolEraTest >> metaWithVersion: aVersion [

	^ '"_meta":{"io.modelcontextprotocol/protocolVersion":"' , aVersion , '"}'
]

{ #category : 'tests' }
MCPProtocolEraTest >> testAModernRequestNamingASupportedVersionIsAnswered [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{'
		            , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	self assert: (response includesSubstring: '"result"').
	self deny: (response includesSubstring: '"error"')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testAModernRequestNamingAnUnsupportedVersionIsRefused [
	"There is no handshake to fall back on, so the request itself is refused and told what would work."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{'
		            , (self metaWithVersion: '1900-01-01') , '}}'.
	self assert: (response includesSubstring: '"code":-32022').
	self assert: (response includesSubstring: '"message":"Unsupported protocol version"').
	self assert: (response includesSubstring: '"requested":"1900-01-01"').
	self assert: (response includesSubstring: MCP latestProtocolVersion)
]

{ #category : 'tests' }
MCPProtocolEraTest >> testALegacyRequestIsUnaffectedByTheVersionCheck [
	"A legacy client names its version once, in initialize, and nothing per request."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'.
	self assert: (response includesSubstring: '"result"').
	self deny: (response includesSubstring: '-32022')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testInitializeStillNegotiatesTheOldWay [
	"Legacy semantics are untouched: the server answers a version it supports rather than refusing."

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"1900-01-01","capabilities":{},"clientInfo":{},"websiteUrl":null}}'.
	self assert: (response includesSubstring: '"result"').
	self assert: (response includesSubstring: MCP latestProtocolVersion).
	self deny: (response includesSubstring: '-32022')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testDiscoverAnswersEvenForAVersionTheServerRefuses [
	"Discovery is how a client learns which versions would work, so refusing it would leave nothing to retry with."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{'
		            , (self metaWithVersion: '1900-01-01') , '}}'.
	self assert: (response includesSubstring: '"supportedVersions"').
	self deny: (response includesSubstring: '-32022')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testDiscoverCarriesVersionsCapabilitiesAndIdentity [

	| result |
	result := self mcpWithoutObservabilityExport rpcServerDiscover.
	self assert: (result at: #supportedVersions) equals: MCP supportedProtocolVersions.
	self assert: ((result at: #capabilities) includesKey: #tools).
	self assert: ((result at: #_meta) at: 'io.modelcontextprotocol/serverInfo') notNil.
	self deny: (result at: #instructions) isEmpty
]

{ #category : 'tests' }
MCPProtocolEraTest >> testDiscoverAndInitializeAgreeOnWhoTheServerIs [
	"One identity, so a client cannot be told two different things depending on which era it speaks."

	| mcp discovered initialized |
	mcp := self mcpWithoutObservabilityExport.
	discovered := (mcp rpcServerDiscover at: #_meta) at: 'io.modelcontextprotocol/serverInfo'.
	initialized := (mcp
		               onInitialize: nil
		               capabilities: nil
		               clientInfo: nil
		               websiteUrl: nil) serverInfo asJRPCJSON.
	self assert: discovered equals: initialized
]

{ #category : 'tests' }
MCPProtocolEraTest >> testReadingTheDeclaredVersion [

	self assert: (MCP requestedProtocolVersionIn: nil) isNil.
	self assert: (MCP requestedProtocolVersionIn: Dictionary new) isNil.
	self assert: (MCP requestedProtocolVersionIn: { ('_meta' -> Dictionary new) } asDictionary) isNil.
	self
		assert: (MCP requestedProtocolVersionIn:
				 { ('_meta' -> { ('io.modelcontextprotocol/protocolVersion' -> '2026-07-28') } asDictionary) } asDictionary)
		equals: '2026-07-28'
]
