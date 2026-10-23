"
Collects what the probes installed by debug_watch observe while an expression runs.

A probe's script is compiled against the frame it fires in and names this class directly, so the recorder is reachable from compiled script source rather than passed in. It holds one recording at a time: debug_watch installs its probes, runs the expression, and takes the recording back before removing them.
"
Class {
	#name : 'MCPDebugWatchRecorder',
	#superclass : 'Object',
	#instVars : [
		'hits',
		'limit'
	],
	#classVars : [
		'Current'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'accessing' }
MCPDebugWatchRecorder class >> current [

	^ Current
]

{ #category : 'recording' }
MCPDebugWatchRecorder class >> record: aProbeIndex value: aValue [
	"Called from compiled probe scripts. A probe that outlives its recording must not fail."

	Current ifNil: [ ^ aValue ].
	Current record: aProbeIndex value: aValue.
	^ aValue
]

{ #category : 'recording' }
MCPDebugWatchRecorder class >> recordingLimited: aLimit during: aBlock [
	"Answer the hits observed while aBlock runs. Recordings do not nest: debug_watch is the only
	caller and it holds the image while its expression runs."

	| previous recorder |
	previous := Current.
	recorder := self new limit: aLimit.
	Current := recorder.
	^ [
	  aBlock value.
	  recorder hits ] ensure: [ Current := previous ]
]

{ #category : 'accessing' }
MCPDebugWatchRecorder >> hits [

	^ hits
]

{ #category : 'initialization' }
MCPDebugWatchRecorder >> initialize [

	super initialize.
	hits := OrderedCollection new
]

{ #category : 'accessing' }
MCPDebugWatchRecorder >> isFull [

	^ hits size >= self limit
]

{ #category : 'accessing' }
MCPDebugWatchRecorder >> limit [

	^ limit ifNil: [ 200 ]
]

{ #category : 'accessing' }
MCPDebugWatchRecorder >> limit: anInteger [

	limit := anInteger
]

{ #category : 'recording' }
MCPDebugWatchRecorder >> record: aProbeIndex value: aValue [
	"Printing a watched value runs its printOn:, which the watched code may be in the middle of
	breaking."

	| text |
	self isFull ifTrue: [ ^ self ].
	text := [ aValue printString ] on: Error do: [ :error | '<unprintable>' ].
	hits add: aProbeIndex -> text
]
