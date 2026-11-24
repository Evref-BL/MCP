"
An edge of the directly-follows graph of one object type: some object, in count cases in all, went from a call of the source activity directly to a call of the target activity, the next call that involved it. The gap is the time between the two calls' starts.
"
Class {
	#name : 'MCPOcelEdge',
	#superclass : 'Object',
	#instVars : [
		'source',
		'target',
		'count',
		'totalGapMilliseconds',
		'objectIds'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOcelEdge class >> from: sourceActivity to: targetActivity [

	^ self new
		  setSource: sourceActivity target: targetActivity;
		  yourself
]

{ #category : 'recording' }
MCPOcelEdge >> addCaseOfObject: anObjectId gapMilliseconds: aNumber [

	count := count + 1.
	totalGapMilliseconds := totalGapMilliseconds + aNumber.
	objectIds add: anObjectId
]

{ #category : 'accessing' }
MCPOcelEdge >> count [

	^ count
]

{ #category : 'accessing' }
MCPOcelEdge >> isSelfLoop [

	^ source = target
]

{ #category : 'accessing' }
MCPOcelEdge >> meanGapMilliseconds [

	^ count = 0
		  ifTrue: [ 0 ]
		  ifFalse: [ totalGapMilliseconds / count ]
]

{ #category : 'accessing' }
MCPOcelEdge >> objectCount [
	"How many different objects went this way."

	^ objectIds size
]

{ #category : 'accessing' }
MCPOcelEdge >> objectIds [

	^ objectIds
]

{ #category : 'initialization' }
MCPOcelEdge >> setSource: sourceActivity target: targetActivity [

	source := sourceActivity.
	target := targetActivity.
	count := 0.
	totalGapMilliseconds := 0.
	objectIds := Set new
]

{ #category : 'accessing' }
MCPOcelEdge >> source [

	^ source
]

{ #category : 'accessing' }
MCPOcelEdge >> target [

	^ target
]
