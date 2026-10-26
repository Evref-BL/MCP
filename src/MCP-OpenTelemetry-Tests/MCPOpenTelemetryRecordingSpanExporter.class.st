"
A span exporter that keeps every snapshot handed to it, so a test can read back what the OpenTelemetry backend actually exported.

It follows OTNoopSpanExporter: the export respects the exporter lock and stops recording once the exporter is shut down.
"
Class {
	#name : 'MCPOpenTelemetryRecordingSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'snapshots'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'exporting' }
MCPOpenTelemetryRecordingSpanExporter >> export: spanSnapshots [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  snapshots addAll: spanSnapshots.
			  true ]
]

{ #category : 'initialization' }
MCPOpenTelemetryRecordingSpanExporter >> initialize [

	super initialize.
	snapshots := OrderedCollection new
]

{ #category : 'accessing' }
MCPOpenTelemetryRecordingSpanExporter >> onlySnapshot [
	"The one span this exporter was given, so a test that expects a single span
	fails here rather than on a confusing assertion further down."

	snapshots size = 1 ifFalse: [ self error: 'Expected exactly one exported span, got ' , snapshots size printString ].
	^ snapshots first
]

{ #category : 'accessing' }
MCPOpenTelemetryRecordingSpanExporter >> snapshots [

	^ snapshots
]
