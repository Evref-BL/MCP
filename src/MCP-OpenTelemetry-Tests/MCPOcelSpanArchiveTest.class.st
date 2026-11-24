"
The file the spans of the call graph are saved in and read back from.
"
Class {
	#name : 'MCPOcelSpanArchiveTest',
	#superclass : 'TestCase',
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'fixtures' }
MCPOcelSpanArchiveTest >> someSpans [

	^ {
		  (MCPOcelTestSpan
			   tool: 'evaluate'
			   id: 'a1'
			   parent: nil
			   startMillisecond: 0
			   durationMilliseconds: 40
			   session: 's1'
			   failed: false).
		  (MCPOcelTestSpan
			   tool: 'class_get'
			   id: 'a2'
			   parent: 'a1'
			   startMillisecond: 5
			   durationMilliseconds: 10
			   session: 's1'
			   failed: true).
		  (MCPOcelTestSpan
			   tool: 'method_get'
			   id: 'a3'
			   parent: nil
			   startMillisecond: 100
			   durationMilliseconds: 10
			   session: 's2'
			   failed: false) }
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testAFileIsWrittenAndReadBack [

	| file spans |
	file := FileReference newTempFilePrefix: 'ocel-' suffix: '.json'.
	[
		MCPOcelSpanArchive write: self someSpans to: file.
		spans := MCPOcelSpanArchive readSpansFrom: file ] ensure: [ file ensureDelete ].
	self assert: (spans collect: #spanId) asArray equals: #( 'a1' 'a2' 'a3' ).
	self assert: (spans collect: #status) asArray equals: {
			OTSpan unset.
			OTSpan error.
			OTSpan unset }
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testAFileThatIsNotOfSpansIsRefused [

	self should: [ MCPOcelSpanArchive spansFromJson: '{"hello": 1}' ] raise: Error.
	self should: [ MCPOcelSpanArchive spansFromJson: 'not json at all' ] raise: Error
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testAnOcel2FileOfAnotherToolGivesItsEventTypesAsTools [

	| spans |
	spans := MCPOcelSpanArchive spansFromJson: '{
		"objectTypes": [{"name": "session", "attributes": []}],
		"eventTypes": [{"name": "search", "attributes": []}],
		"objects": [{"id": "s-9", "type": "session", "attributes": []}],
		"events": [{"id": "e1", "type": "search", "time": "2026-03-01T10:00:00Z",
			"attributes": [], "relationships": [{"objectId": "s-9", "qualifier": "in"}]}]}'.
	self assert: spans size equals: 1.
	self assert: (MCPOcelLog fromSpanSnapshots: spans) events first activity equals: 'search'.
	self assert: ((MCPOcelLog fromSpanSnapshots: spans) objectIdsOfType: 'session') asArray equals: #( 's-9' )
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testOcel2HasTheFourSectionsOfTheFormat [

	| root |
	root := STONJSON fromString: (MCPOcel2Archive jsonFor: (MCPOcelLog fromSpanSnapshots: self someSpans)).
	self assert: root keys asSortedCollection asArray equals: #( 'eventTypes' 'events' 'objectTypes' 'objects' ).
	self assert: (root at: 'events') size equals: 3.
	self
		assert: ((root at: 'objects') collect: [ :each | each at: 'id' ]) asSet
		equals: #( 'tool:evaluate' 'tool:class_get' 'tool:method_get' 'session:s1' 'session:s2' ) asSet
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testOcel2ReadBackGivesTheSameLog [

	| before after json |
	before := MCPOcelLog fromSpanSnapshots: self someSpans.
	json := MCPOcel2Archive jsonFor: before.
	after := MCPOcelLog fromSpanSnapshots: (MCPOcelSpanArchive spansFromJson: json).
	self assert: (after events collect: #id) equals: (before events collect: #id).
	self assert: (after events collect: #activity) equals: (before events collect: #activity).
	self assert: (after events collect: #startedAt) equals: (before events collect: #startedAt).
	self assert: (after events collect: #finishedAt) equals: (before events collect: #finishedAt).
	self assert: (after events collect: #isError) equals: (before events collect: #isError).
	self assert: (after events collect: #parentId) equals: (before events collect: #parentId).
	before objectTypes do: [ :type |
			self
				assert: (after objectIdsOfType: type) asSortedCollection asArray
				equals: (before objectIdsOfType: type) asSortedCollection asArray ]
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testSpansReadBackGiveTheSameLog [

	| before after |
	before := MCPOcelLog fromSpanSnapshots: self someSpans.
	after := MCPOcelLog fromSpanSnapshots: (MCPOcelSpanArchive spansFromJson: (MCPOcelSpanArchive jsonFor: self someSpans)).
	self assert: (after events collect: #id) equals: (before events collect: #id).
	self assert: (after events collect: #activity) equals: (before events collect: #activity).
	self assert: (after events collect: #startedAt) equals: (before events collect: #startedAt).
	self assert: (after events collect: #isError) equals: (before events collect: #isError).
	self assert: (after events collect: #parentId) equals: (before events collect: #parentId).
	MCPOcelLog new objectTypes do: [ :type |
			self
				assert: (after objectIdsOfType: type) asSortedCollection asArray
				equals: (before objectIdsOfType: type) asSortedCollection asArray ]
]

{ #category : 'tests' }
MCPOcelSpanArchiveTest >> testTheStoreAddsOnlyTheSpansItDoesNotHold [

	| store spans |
	store := MCPOpenTelemetryLocalSpanStore new.
	spans := MCPOcelSpanArchive spansFromJson: (MCPOcelSpanArchive jsonFor: self someSpans).
	self assert: (store addAllNew: spans) equals: 3.
	self assert: (store addAllNew: spans) equals: 0.
	self assert: store size equals: 3
]
