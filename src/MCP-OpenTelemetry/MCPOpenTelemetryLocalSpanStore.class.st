"
The spans the image keeps in memory for itself, to be read back by what inspects it, such as the call graph of the inspector, whether or not any are exported. It holds the most recent maxSpans snapshots, oldest dropped first. It outlives the providers: a reconfiguration shuts down the exporter that fed it and makes another, which feeds the same store.
"
Class {
	#name : 'MCPOpenTelemetryLocalSpanStore',
	#superclass : 'Object',
	#instVars : [
		'snapshots',
		'mutex',
		'maxSpans'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'adding' }
MCPOpenTelemetryLocalSpanStore >> addAll: spanSnapshots [

	mutex critical: [
			snapshots addAll: spanSnapshots.
			[ snapshots size > maxSpans ] whileTrue: [ snapshots removeFirst ] ]
]

{ #category : 'adding' }
MCPOpenTelemetryLocalSpanStore >> addAllNew: someSpans [
	"Adds those whose span id the store does not hold yet, so that loading a file twice, or one of spans the image still holds, adds nothing twice. Answers how many were added."

	| known new |
	^ mutex critical: [
			  known := (snapshots collect: [ :each | each spanId ]) asSet.
			  new := someSpans reject: [ :each | known includes: each spanId ].
			  snapshots addAll: new.
			  [ snapshots size > maxSpans ] whileTrue: [ snapshots removeFirst ].
			  new size ]
]

{ #category : 'removing' }
MCPOpenTelemetryLocalSpanStore >> clear [

	mutex critical: [ snapshots removeAll ]
]

{ #category : 'initialization' }
MCPOpenTelemetryLocalSpanStore >> initialize [

	super initialize.
	snapshots := OrderedCollection new.
	mutex := Mutex new.
	maxSpans := 5000
]

{ #category : 'accessing' }
MCPOpenTelemetryLocalSpanStore >> maxSpans [

	^ maxSpans
]

{ #category : 'accessing' }
MCPOpenTelemetryLocalSpanStore >> maxSpans: anInteger [

	mutex critical: [
			maxSpans := anInteger.
			[ snapshots size > maxSpans ] whileTrue: [ snapshots removeFirst ] ]
]

{ #category : 'accessing' }
MCPOpenTelemetryLocalSpanStore >> size [

	^ mutex critical: [ snapshots size ]
]

{ #category : 'accessing' }
MCPOpenTelemetryLocalSpanStore >> snapshots [
	"The spans kept, oldest first, as a copy that later exports do not change."

	^ mutex critical: [ snapshots asArray ]
]
