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
MCPProtocolEraTest >> testAModernResultSaysItIsComplete [
	"Every result in the modern era declares its kind, so a client can tell an ordinary result from an interim one."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{'
		            , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	self assert: (response includesSubstring: '"resultType":"complete"')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testALegacyResultCarriesNoResultType [
	"resultType belongs to a revision a legacy client never asked for."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'.
	self assert: (response includesSubstring: '"result"').
	self deny: (response includesSubstring: 'resultType')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testResourceNotFoundIsRenumberedForModernRequests [
	"The revision folds resource-not-found into invalid params; earlier revisions give it a code of its own."

	| legacy modern |
	legacy := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":"pharo://missing"}}'.
	modern := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{"uri":"pharo://missing",'
		          , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	self assert: (legacy includesSubstring: '"code":-32002').
	self assert: (modern includesSubstring: '"code":-32602').
	self assert: (modern includesSubstring: '"uri":"pharo://missing"')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testAnErrorWithNoModernCodeIsUnchanged [
	"Only the conditions the revision renumbered move; everything else answers the same code in both eras."

	| modern |
	modern := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"prompts/get","params":{"name":"no_such_prompt",'
		          , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	self assert: (modern includesSubstring: '"code":-32602')
]

{ #category : 'private' }
MCPProtocolEraTest >> listenStreamFor: aFilterFragment [

	| server body |
	server := MCPHTTPServer new.
	body := STONJSON fromString:
		        '{"jsonrpc":"2.0","id":7,"method":"subscriptions/listen","params":{"notifications":{' , aFilterFragment , '},'
		        , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	server answerSubscriptionsListen: body with: ZnResponse new.
	^ server eventStreams last
]

{ #category : 'tests' }
MCPProtocolEraTest >> testListenAcknowledgesBeforeAnythingElse [
	"The revision requires the acknowledgement to be the first message on the subscription."

	| stream |
	stream := self listenStreamFor: '"toolsListChanged":true'.
	self assert: (stream pendingEvents first includesSubstring: 'notifications/subscriptions/acknowledged').
	self assert: (stream pendingEvents first includesSubstring: '"io.modelcontextprotocol/subscriptionId":7')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testListenCarriesOnlyWhatWasAskedFor [
	"A server must not send a notification type the client did not ask for."

	| stream |
	stream := self listenStreamFor: '"toolsListChanged":true'.
	self assert: (stream accepts: 'notifications/tools/list_changed').
	self deny: (stream accepts: 'notifications/prompts/list_changed').
	self deny: (stream accepts: 'notifications/resources/list_changed')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testAcknowledgementOmitsWhatTheServerCannotDo [
	"resourceSubscriptions promises notifications/resources/updated, and no resource here can say it changed."

	| stream acknowledged |
	stream := self listenStreamFor: '"toolsListChanged":true,"resourceSubscriptions":["pharo://image/metadata"]'.
	acknowledged := ((STONJSON fromString: stream pendingEvents first) at: 'params') at: 'notifications'.
	self assert: (acknowledged at: 'toolsListChanged').
	self deny: (acknowledged includesKey: 'resourceSubscriptions')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testNotificationsOnASubscriptionCarryItsId [

	| stream notification |
	stream := self listenStreamFor: '"toolsListChanged":true'.
	stream writeNotification: 'notifications/tools/list_changed' parameters: nil.
	notification := STONJSON fromString: stream pendingEvents last.
	self assert: (notification at: 'method') equals: 'notifications/tools/list_changed'.
	self assert: (((notification at: 'params') at: '_meta') at: 'io.modelcontextprotocol/subscriptionId') equals: 7
]

{ #category : 'tests' }
MCPProtocolEraTest >> testALegacyStreamCarriesEverythingAndNamesNoSubscription [
	"A GET stream was opened without a filter, so it agreed to everything and belongs to no subscription."

	| stream notification |
	stream := MCPEventStream new.
	self assert: (stream accepts: 'notifications/tools/list_changed').
	stream writeNotification: 'notifications/tools/list_changed' parameters: nil.
	notification := STONJSON fromString: stream pendingEvents last.
	self deny: (notification includesKey: 'params')
]

{ #category : 'private' }
MCPProtocolEraTest >> modernResultFor: aMethod params: aParamsFragment [

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"' , aMethod , '","params":{' , aParamsFragment
		            , (self metaWithVersion: MCP latestProtocolVersion) , '}}'.
	^ (STONJSON fromString: response) at: 'result'
]

{ #category : 'tests' }
MCPProtocolEraTest >> testACatalogSaysHowLongItStaysGood [

	| result |
	result := self modernResultFor: 'tools/list' params: ''.
	self assert: (result at: 'ttlMs') equals: MCP catalogCacheMilliseconds.
	self assert: (result at: 'cacheScope') equals: 'public'
]

{ #category : 'tests' }
MCPProtocolEraTest >> testResourceContentsAreCachedPrivatelyAndBriefly [
	"Nothing announces that a resource's contents changed, so the window is short, and contents are where anything caller-specific would first appear."

	| result |
	result := self modernResultFor: 'resources/read' params: '"uri":"pharo://image/metadata",'.
	self assert: (result at: 'ttlMs') equals: MCP resourceContentsCacheMilliseconds.
	self assert: (result at: 'cacheScope') equals: 'private'
]

{ #category : 'tests' }
MCPProtocolEraTest >> testEveryCacheableOperationCarriesHints [
	"The revision names six operations that must carry them."

	#( 'server/discover' 'tools/list' 'prompts/list' 'resources/list' 'resources/templates/list' ) do: [ :each |
			| result |
			result := self modernResultFor: each params: ''.
			self assert: (result includesKey: 'ttlMs') description: each , ' carries no ttlMs'.
			self assert: (result at: 'ttlMs') >= 0 description: each , ' has a negative ttlMs'.
			self assert: (result includesKey: 'cacheScope') description: each , ' carries no cacheScope' ]
]

{ #category : 'tests' }
MCPProtocolEraTest >> testAnOperationThatIsNotCacheableCarriesNoHints [

	| result |
	result := self modernResultFor: 'ping' params: ''.
	self assert: (result at: 'resultType') equals: 'complete'.
	self deny: (result includesKey: 'ttlMs')
]

{ #category : 'tests' }
MCPProtocolEraTest >> testALegacyCatalogCarriesNoCachingHints [
	"Caching hints belong to a revision a legacy client never asked for."

	| response |
	response := self handleJSON: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'.
	self deny: (response includesSubstring: 'ttlMs').
	self deny: (response includesSubstring: 'cacheScope')
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
