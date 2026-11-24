"
The directly-follows graph of one object type of a MCPOcelLog, in the sense of object-centric process mining: each object of the type has the sequence of the calls that involve it, in the order of their start, and the graph counts which activity follows which in those sequences. The activities are the tools called; they carry how many calls, how many failed and how long they took, over the calls that involve an object of the type.
"
Class {
	#name : 'MCPOcelFlowGraph',
	#superclass : 'Object',
	#instVars : [
		'objectType',
		'edges',
		'activityCounts',
		'activityErrorCounts',
		'activityTotalDurations'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOcelFlowGraph class >> ofType: anObjectType in: anOcelLog [

	^ self new
		  buildType: anObjectType from: anOcelLog;
		  yourself
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> activities [
	"The tools called, by name."

	^ activityCounts keys sorted
]

{ #category : 'building' }
MCPOcelFlowGraph >> buildType: anObjectType from: anOcelLog [
	"Flattens the log on the type: each object of it has the calls that involve it in the order of their start, and each two that follow one another make a case of the edge between their activities."

	objectType := anObjectType.
	edges := Dictionary new.
	activityCounts := Dictionary new.
	activityErrorCounts := Dictionary new.
	activityTotalDurations := Dictionary new.
	(anOcelLog events select: [ :event | event involvesObjectType: anObjectType ]) do: [ :event |
			activityCounts at: event activity put: (activityCounts at: event activity ifAbsent: [ 0 ]) + 1.
			activityTotalDurations
				at: event activity
				put: (activityTotalDurations at: event activity ifAbsent: [ 0 ]) + event durationMilliseconds.
			event isError ifTrue: [
				activityErrorCounts at: event activity put: (activityErrorCounts at: event activity ifAbsent: [ 0 ]) + 1 ] ].
	(anOcelLog objectIdsOfType: anObjectType) do: [ :objectId |
			| sequence |
			sequence := anOcelLog eventsOfObject: objectId type: anObjectType.
			sequence overlappingPairsDo: [ :before :after |
					(edges at: before activity -> after activity ifAbsentPut: [ MCPOcelEdge from: before activity to: after activity ])
						addCaseOfObject: objectId
						gapMilliseconds: (after startedAt - before startedAt) asMilliSeconds ] ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> callCountOf: anActivity [

	^ activityCounts at: anActivity ifAbsent: [ 0 ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> edgeFrom: source to: target [

	^ edges at: source -> target ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> edges [
	"The edges, most followed first."

	^ edges values asSortedCollection: [ :a :b | a count > b count or: [ a count = b count and: [ a source <= b source ] ] ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> errorCountOf: anActivity [

	^ activityErrorCounts at: anActivity ifAbsent: [ 0 ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> meanDurationMillisecondsOf: anActivity [

	| calls |
	calls := self callCountOf: anActivity.
	^ calls = 0
		  ifTrue: [ 0 ]
		  ifFalse: [ (activityTotalDurations at: anActivity) / calls ]
]

{ #category : 'accessing' }
MCPOcelFlowGraph >> objectType [

	^ objectType
]
