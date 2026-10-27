"
Tests the header validation a modern request is held to.

The 2026-07-28 revision mirrors the method, version and named thing into headers so intermediaries can route without parsing the body. That only holds if the two always agree, so a header that is missing or different is refused rather than reconciled. A legacy request carries none of them and is not asked to.
"
Class {
	#name : 'MCPModernHeaderTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPModernHeaderTest >> mismatchFor: aBody headers: someAssociations [

	^ MCPHTTPServer new headerMismatchFor: (self requestFor: aBody headers: someAssociations)
]

{ #category : 'private' }
MCPModernHeaderTest >> modernBodyFor: aMethod params: aParamsFragment [

	^ '{"jsonrpc":"2.0","id":1,"method":"' , aMethod , '","params":{' , aParamsFragment
	  , '"_meta":{"io.modelcontextprotocol/protocolVersion":"' , MCP latestProtocolVersion , '"}}}'
]

{ #category : 'private' }
MCPModernHeaderTest >> requestFor: aBody headers: someAssociations [

	| request |
	request := ZnRequest post: 'http://127.0.0.1/'.
	request entity: (ZnEntity json: aBody).
	someAssociations do: [ :each | request headers at: each key put: each value ].
	^ request
]

{ #category : 'tests' }
MCPModernHeaderTest >> testALegacyRequestIsNotAskedForHeaders [
	"A legacy client never sent these headers and must not start failing for want of them."

	self assert: (self mismatchFor: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' headers: #(  )) isNil
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAMatchingSetOfHeadersPasses [

	| body |
	body := self modernBodyFor: 'tools/call' params: '"name":"tool_search",'.
	self assert: (self mismatchFor: body headers: {
				 ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
				 ('Mcp-Method' -> 'tools/call').
				 ('Mcp-Name' -> 'tool_search') }) isNil
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAMethodHeaderDisagreeingWithTheBodyIsRefused [
	"A proxy routing on the header while the server runs the body is the hole this closes."

	| mismatch |
	mismatch := self mismatchFor: (self modernBodyFor: 'tools/list' params: '') headers: {
			            ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
			            ('Mcp-Method' -> 'resources/read') }.
	self assert: ((mismatch at: 'error') at: 'code') equals: -32020.
	self assert: (((mismatch at: 'error') at: 'message') includesSubstring: 'tools/list')
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAMethodThatNamesNothingNeedsNoNameHeader [

	| body |
	body := self modernBodyFor: 'tools/list' params: ''.
	self assert: (self mismatchFor: body headers: {
				 ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
				 ('Mcp-Method' -> 'tools/list') }) isNil
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAMissingMethodHeaderIsRefused [

	| mismatch |
	mismatch := self mismatchFor: (self modernBodyFor: 'tools/list' params: '') headers:
		            { ('MCP-Protocol-Version' -> MCP latestProtocolVersion) }.
	self assert: ((mismatch at: 'error') at: 'code') equals: -32020.
	self assert: (((mismatch at: 'error') at: 'message') includesSubstring: 'Mcp-Method')
]

{ #category : 'tests' }
MCPModernHeaderTest >> testANameTooAwkwardForAHeaderTravelsEncoded [
	"A value that cannot be plain ASCII arrives wrapped, and has to be decoded before it is compared."

	| body |
	body := self modernBodyFor: 'prompts/get' params: '"name":"Hello, 世界",'.
	self assert: (self mismatchFor: body headers: {
				 ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
				 ('Mcp-Method' -> 'prompts/get').
				 ('Mcp-Name' -> '=?base64?SGVsbG8sIOS4lueVjA==?=') }) isNil
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAVersionHeaderDisagreeingWithTheBodyIsRefused [

	| mismatch |
	mismatch := self mismatchFor: (self modernBodyFor: 'tools/list' params: '') headers: {
			            ('MCP-Protocol-Version' -> '2025-03-26').
			            ('Mcp-Method' -> 'tools/list') }.
	self assert: ((mismatch at: 'error') at: 'code') equals: -32020
]

{ #category : 'tests' }
MCPModernHeaderTest >> testAnEncodedNameThatDecodesToSomethingElseIsRefused [

	| mismatch |
	mismatch := self mismatchFor: (self modernBodyFor: 'prompts/get' params: '"name":"greet",') headers: {
			            ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
			            ('Mcp-Method' -> 'prompts/get').
			            ('Mcp-Name' -> '=?base64?SGVsbG8sIOS4lueVjA==?=') }.
	self assert: ((mismatch at: 'error') at: 'code') equals: -32020
]

{ #category : 'tests' }
MCPModernHeaderTest >> testTheNameHeaderMirrorsTheUriForAResourceRead [

	| body |
	body := self modernBodyFor: 'resources/read' params: '"uri":"pharo://image/metadata",'.
	self assert: (self mismatchFor: body headers: {
				 ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
				 ('Mcp-Method' -> 'resources/read').
				 ('Mcp-Name' -> 'pharo://image/metadata') }) isNil.
	self assert: ((self mismatchFor: body headers: {
				  ('MCP-Protocol-Version' -> MCP latestProtocolVersion).
				  ('Mcp-Method' -> 'resources/read') }) at: 'error') notNil
]
