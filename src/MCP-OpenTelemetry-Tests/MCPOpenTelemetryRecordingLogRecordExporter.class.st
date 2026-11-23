"
A log record exporter that keeps every log record handed to it, so a test can read back the events the OpenTelemetry backend emitted.
"
Class {
	#name : 'MCPOpenTelemetryRecordingLogRecordExporter',
	#superclass : 'OTLogRecordExporter',
	#instVars : [
		'records'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'accessing' }
MCPOpenTelemetryRecordingLogRecordExporter >> eventNames [
	"The names of the events exported, in order."

	^ records collect: [ :each | each eventName ] as: Array
]

{ #category : 'exporting' }
MCPOpenTelemetryRecordingLogRecordExporter >> export: someLogRecords [

	self isShutdown ifTrue: [ ^ false ].
	records addAll: someLogRecords.
	^ true
]

{ #category : 'initialization' }
MCPOpenTelemetryRecordingLogRecordExporter >> initialize [

	super initialize.
	records := OrderedCollection new
]

{ #category : 'accessing' }
MCPOpenTelemetryRecordingLogRecordExporter >> records [

	^ records
]
