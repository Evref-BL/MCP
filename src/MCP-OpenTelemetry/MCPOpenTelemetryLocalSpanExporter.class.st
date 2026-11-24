"
A span exporter that hands every snapshot to a MCPOpenTelemetryLocalSpanStore and sends nothing. It follows OTNoopSpanExporter: the export respects the exporter lock and stops once the exporter is shut down.
"
Class {
	#name : 'MCPOpenTelemetryLocalSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'store'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOpenTelemetryLocalSpanExporter class >> on: aSpanStore [

	^ self new
		  store: aSpanStore;
		  yourself
]

{ #category : 'exporting' }
MCPOpenTelemetryLocalSpanExporter >> export: spanSnapshots [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  store addAll: spanSnapshots.
			  true ]
]

{ #category : 'accessing' }
MCPOpenTelemetryLocalSpanExporter >> store: aSpanStore [

	store := aSpanStore
]
