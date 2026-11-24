"
The object-centric log and the directly-follows graphs read from the spans of tool calls.
"
Class {
	#name : 'MCPOcelLogTest',
	#superclass : 'TestCase',
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'running' }
MCPOcelLogTest >> dispatchingLog [
	"package_search, then tool_call dispatching class_search, then tool_call dispatching package_search, given out of order."

	^ MCPOcelLog fromSpanSnapshots: {
			  (self
				   span: 'package_search'
				   id: 'e'
				   parent: 'd'
				   at: 61
				   for: 3).
			  (self
				   span: 'tool_call'
				   id: 'd'
				   parent: nil
				   at: 60
				   for: 5).
			  (self
				   span: 'class_search'
				   id: 'c'
				   parent: 'b'
				   at: 11
				   for: 3).
			  (self
				   span: 'tool_call'
				   id: 'b'
				   parent: nil
				   at: 10
				   for: 5).
			  (self
				   span: 'package_search'
				   id: 'a'
				   parent: nil
				   at: 0
				   for: 4) }
]

{ #category : 'running' }
MCPOcelLogTest >> failedSpan: aTool id: anId at: start for: duration [

	^ MCPOcelTestSpan
		  tool: aTool
		  id: anId
		  parent: nil
		  startMillisecond: start
		  durationMilliseconds: duration
		  session: 's1'
		  failed: true
]

{ #category : 'running' }
MCPOcelLogTest >> span: aTool id: anId parent: aParent at: start for: duration [

	^ MCPOcelTestSpan
		  tool: aTool
		  id: anId
		  parent: aParent
		  startMillisecond: start
		  durationMilliseconds: duration
		  session: 's1'
		  failed: false
]

{ #category : 'tests' }
MCPOcelLogTest >> testACallStartingWithItsDispatcherComesAfterIt [

	| log |
	log := MCPOcelLog fromSpanSnapshots: {
			       (self
				        span: 'class_search'
				        id: 'child'
				        parent: 'root'
				        at: 0
				        for: 1).
			       (self
				        span: 'tool_call'
				        id: 'root'
				        parent: nil
				        at: 0
				        for: 2) }.
	self assert: (log events collect: #id) asArray equals: #( 'root' 'child' ).
	self assert: (log events collect: #depth) asArray equals: #( 0 1 )
]

{ #category : 'tests' }
MCPOcelLogTest >> testASpanWhoseParentIsNotInTheLogIsARoot [

	| log |
	log := MCPOcelLog fromSpanSnapshots: { (self
			        span: 'class_search'
			        id: 'x'
			        parent: 'elsewhere'
			        at: 0
			        for: 1) }.
	self assert: log events first parentId isNil.
	self assert: (log events first objectIdsOfType: 'tool') asArray equals: #( 'class_search' )
]

{ #category : 'tests' }
MCPOcelLogTest >> testActivitiesCarryHowManyCallsFailedAndHowLongTheyTook [

	| graph |
	graph := (MCPOcelLog fromSpanSnapshots: {
			          (self
				           span: 'class_get'
				           id: 'a'
				           parent: nil
				           at: 0
				           for: 10).
			          (self
				           failedSpan: 'class_get'
				           id: 'b'
				           at: 20
				           for: 30) }) flowGraphOfType: 'tool'.
	self assert: (graph callCountOf: 'class_get') equals: 2.
	self assert: (graph errorCountOf: 'class_get') equals: 1.
	self assert: (graph meanDurationMillisecondsOf: 'class_get') equals: 20
]

{ #category : 'tests' }
MCPOcelLogTest >> testAnObjectTypeNoCallInvolvesHasAnEmptyGraph [

	| graph |
	graph := self dispatchingLog flowGraphOfType: 'client'.
	self assert: graph activities isEmpty.
	self assert: graph edges isEmpty
]

{ #category : 'tests' }
MCPOcelLogTest >> testEventsFollowTheStartOfTheirCallWhateverTheOrderOfTheSpans [

	self assert: (self dispatchingLog events collect: #id) asArray equals: #( 'a' 'b' 'c' 'd' 'e' )
]

{ #category : 'tests' }
MCPOcelLogTest >> testTheSessionGraphFollowsTheCallsOfASessionInTheOrderTheyStarted [

	| graph edge |
	graph := self dispatchingLog flowGraphOfType: 'session'.
	self assert: graph edges size equals: 4.
	edge := graph edgeFrom: 'package_search' to: 'tool_call'.
	self assert: edge count equals: 1.
	self assert: edge meanGapMilliseconds equals: 10.
	self assert: edge objectCount equals: 1.
	self assert: (graph edgeFrom: 'tool_call' to: 'class_search') meanGapMilliseconds equals: 1.
	self assert: (graph edgeFrom: 'class_search' to: 'tool_call') meanGapMilliseconds equals: 49
]

{ #category : 'tests' }
MCPOcelLogTest >> testTheToolGraphFollowsEachToolThroughTheCallsThatInvolveIt [

	| graph |
	graph := self dispatchingLog flowGraphOfType: 'tool'.
	self assert: graph activities equals: #( 'class_search' 'package_search' 'tool_call' ).
	self assert: (graph edgeFrom: 'tool_call' to: 'class_search') count equals: 1.
	self assert: (graph edgeFrom: 'class_search' to: 'tool_call') count equals: 1.
	self assert: (graph edgeFrom: 'tool_call' to: 'package_search') count equals: 1.
	self assert: (graph edgeFrom: 'package_search' to: 'package_search') count equals: 1.
	self assert: (graph edgeFrom: 'tool_call' to: 'tool_call') isNil
]

{ #category : 'tests' }
MCPOcelLogTest >> testTheToolThatDispatchedACallIsOneOfItsToolObjects [

	| child |
	child := self dispatchingLog events detect: [ :event | event id = 'c' ].
	self assert: (child objectIdsOfType: 'tool') asArray equals: #( 'class_search' 'tool_call' ).
	self assert: (child objectIdsOfType: 'session') asArray equals: #( 's1' )
]
