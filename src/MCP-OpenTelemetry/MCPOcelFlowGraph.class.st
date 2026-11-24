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
		'activityTotalDurations',
		'activityFirstStarts'
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

{ #category : 'accessing' }
MCPOcelFlowGraph >> activitiesByFirstCall [
	"The tools called, the one called first first. The log is in the order of the calls' start, which an activity inherits from its first call."

	^ activityFirstStarts keys sorted: [ :a :b |
			  (activityFirstStarts at: a) < (activityFirstStarts at: b) or: [
				  (activityFirstStarts at: a) = (activityFirstStarts at: b) and: [ a <= b ] ] ]
]

{ #category : 'building' }
MCPOcelFlowGraph >> buildType: anObjectType from: anOcelLog [
	"Flattens the log on the type: each object of it has the calls that involve it in the order of their start, and each two that follow one another make a case of the edge between their activities."

	objectType := anObjectType.
	edges := Dictionary new.
	activityCounts := Dictionary new.
	activityErrorCounts := Dictionary new.
	activityTotalDurations := Dictionary new.
	activityFirstStarts := Dictionary new.
	anOcelLog events do: [ :event |
			(event involvesObjectType: anObjectType) ifTrue: [
					activityCounts at: event activity put: (activityCounts at: event activity ifAbsent: [ 0 ]) + 1.
					activityTotalDurations
						at: event activity
						put: (activityTotalDurations at: event activity ifAbsent: [ 0 ]) + event durationMilliseconds.
					activityFirstStarts at: event activity ifAbsentPut: [ event startedAt ].
					event isError ifTrue: [
						activityErrorCounts at: event activity put: (activityErrorCounts at: event activity ifAbsent: [ 0 ]) + 1 ] ] ].
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

{ #category : 'layout' }
MCPOcelFlowGraph >> layers [
	"The layer each activity is drawn in, from the left: the longest chain of edges that reaches it from an activity called before it, going from the activity called first. An edge that returns to an activity of the chain being followed, a cycle, is not followed, so that the layers go the way the calls did. An activity the first ones do not reach starts a chain of its own, at layer 0."

	| layers onChain follow |
	layers := Dictionary new.
	onChain := Set new.
	follow := nil.
	follow := [ :activity :layer |
		          ((onChain includes: activity) not and: [ (layers at: activity ifAbsent: [ -1 ]) < layer ]) ifTrue: [
				          layers at: activity put: layer.
				          onChain add: activity.
				          (edges values select: [ :edge | edge source = activity and: [ edge isSelfLoop not ] ]) do: [ :edge |
					          follow value: edge target value: layer + 1 ].
				          onChain remove: activity ] ].
	self activitiesByFirstCall do: [ :activity | layers at: activity ifAbsent: [ follow value: activity value: 0 ] ].
	^ layers
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
