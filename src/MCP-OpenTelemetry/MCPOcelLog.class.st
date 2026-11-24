"
An object-centric event log of tool calls, built from the spans an image kept (MCPOpenTelemetryLocalSpanStore): one event per call, in the order of their start, related to the objects they involve. The central object type is the tool: a call involves the tool it calls and, when another tool dispatched it (tool_call), that tool too, so the sequence of a dispatching tool holds the calls it made. Spans whose parent is not in the log, because it is another system's or it was dropped, are roots.
"
Class {
	#name : 'MCPOcelLog',
	#superclass : 'Object',
	#instVars : [
		'events'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOcelLog class >> fromSpanSnapshots: spanSnapshots [
	"The log of the tool calls the spans describe, whatever order they come in."

	^ self new
		  readSpanSnapshots: spanSnapshots;
		  yourself
]

{ #category : 'reading' }
MCPOcelLog >> depthOf: anEvent in: eventsById [
	"How many calls dispatched this one, one dispatching the next."

	| depth current |
	depth := 0.
	current := anEvent.
	[ current parentId isNotNil and: [ depth < 100 ] ] whileTrue: [
			current := eventsById at: current parentId.
			depth := depth + 1 ].
	^ depth
]

{ #category : 'reading' }
MCPOcelLog >> eventFor: aSpanSnapshot [
	"What the span of a call says: the tool called, when it started and ended, whether it failed, how it was dispatched, the span of the call that dispatched it, and the objects the call involves, but for the dispatching tool, which the log knows."

	| attributes event |
	attributes := aSpanSnapshot attributes.
	event := MCPOcelEvent new
		         id: aSpanSnapshot spanId;
		         activity:
			         ((attributes at: 'gen_ai.tool.name' ifAbsent: [ nil ]) ifNil: [ aSpanSnapshot name withoutPrefix: 'tools/call ' ]);
		         startedAt: aSpanSnapshot startTime;
		         finishedAt: aSpanSnapshot endTime;
		         isError: aSpanSnapshot status = OTSpan error;
		         dispatchPath: (attributes at: 'pharo.mcp.dispatch_path' ifAbsent: [ nil ]);
		         parentId: (aSpanSnapshot parentSpanContext ifNotNil: [ :context | context spanId ]);
		         yourself.
	event addObject: event activity ofType: 'tool'.
	attributes at: 'session.id' ifPresent: [ :session | event addObject: session ofType: 'session' ].
	attributes at: 'pharo.mcp.client.name' ifPresent: [ :client | event addObject: client ofType: 'client' ].
	^ event
]

{ #category : 'accessing' }
MCPOcelLog >> events [
	"The calls, in the order of their start; a call comes after the call that dispatched it."

	^ events ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPOcelLog >> eventsOfObject: anId type: aType [

	^ events select: [ :event | (event objectIdsOfType: aType) includes: anId ]
]

{ #category : 'accessing' }
MCPOcelLog >> flowGraphOfType: anObjectType [

	^ MCPOcelFlowGraph ofType: anObjectType in: self
]

{ #category : 'initialization' }
MCPOcelLog >> initialize [

	super initialize.
	events := OrderedCollection new
]

{ #category : 'accessing' }
MCPOcelLog >> objectIdsOfType: aType [

	^ (self events flatCollect: [ :event | event objectIdsOfType: aType ] as: Set) sorted
]

{ #category : 'accessing' }
MCPOcelLog >> objectTypes [

	^ #( 'tool' 'session' 'client' )
]

{ #category : 'reading' }
MCPOcelLog >> readSpanSnapshots: spanSnapshots [
	"One event per span, ordered by the start of its call, a call after the call that dispatched it when both started at the same time. The tool that dispatched a call is one of its tool objects, when its span is in the log."

	| byId |
	events := (spanSnapshots collect: [ :snapshot | self eventFor: snapshot ]) asOrderedCollection.
	byId := Dictionary new.
	events do: [ :event | byId at: event id put: event ].
	events do: [ :event | event parentId ifNotNil: [ :parentId | byId at: parentId ifAbsent: [ event parentId: nil ] ] ].
	events do: [ :event | event depth: (self depthOf: event in: byId) ].
	events do: [ :event | event parentId ifNotNil: [ :parentId | event addObject: (byId at: parentId) activity ofType: 'tool' ] ].
	events := (events sorted: [ :a :b | a startedAt < b startedAt or: [ a startedAt = b startedAt and: [ a depth <= b depth ] ] ])
		          asOrderedCollection
]
