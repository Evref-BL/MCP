"
What a MCPOcelLog reads of a span snapshot, with the values given, so that a test says when each call started and ended without making spans.
"
Class {
	#name : 'MCPOcelTestSpan',
	#superclass : 'Object',
	#instVars : [
		'name',
		'spanId',
		'parentSpanContext',
		'startTime',
		'endTime',
		'attributes',
		'status'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'instance creation' }
MCPOcelTestSpan class >> tool: aToolName id: anId parent: aParentId startMillisecond: start durationMilliseconds: duration session: aSession failed: aBoolean [

	^ self new
		  setTool: aToolName
		  id: anId
		  parent: aParentId
		  startMillisecond: start
		  durationMilliseconds: duration
		  session: aSession
		  failed: aBoolean;
		  yourself
]

{ #category : 'accessing' }
MCPOcelTestSpan >> attributes [

	^ attributes
]

{ #category : 'accessing' }
MCPOcelTestSpan >> endTime [

	^ endTime
]

{ #category : 'accessing' }
MCPOcelTestSpan >> name [

	^ name
]

{ #category : 'accessing' }
MCPOcelTestSpan >> parentSpanContext [

	^ parentSpanContext
]

{ #category : 'initialization' }
MCPOcelTestSpan >> setTool: aToolName id: anId parent: aParentId startMillisecond: start durationMilliseconds: duration session: aSession failed: aBoolean [
	"Times are milliseconds after a fixed instant."

	| origin |
	origin := DateAndTime
		          year: 2026
		          month: 1
		          day: 1
		          hour: 0
		          minute: 0
		          second: 0
		          offset: Duration zero.
	name := 'tools/call ' , aToolName.
	spanId := anId.
	parentSpanContext := aParentId ifNotNil: [
			                     MCPOcelTestSpanContext new
				                     spanId: aParentId;
				                     yourself ].
	startTime := origin + start milliSeconds.
	endTime := startTime + duration milliSeconds.
	attributes := {
		              ('gen_ai.tool.name' -> aToolName).
		              ('session.id' -> aSession) } asDictionary.
	status := aBoolean
		          ifTrue: [ OTSpan error ]
		          ifFalse: [ OTSpan unset ]
]

{ #category : 'accessing' }
MCPOcelTestSpan >> spanId [

	^ spanId
]

{ #category : 'accessing' }
MCPOcelTestSpan >> startTime [

	^ startTime
]

{ #category : 'accessing' }
MCPOcelTestSpan >> status [

	^ status
]
