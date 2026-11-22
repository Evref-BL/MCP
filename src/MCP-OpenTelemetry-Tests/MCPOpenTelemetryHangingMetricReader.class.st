"
A metric reader whose shutdown waits until it is opened, for at most ten seconds: a collector that does not answer.
"
Class {
	#name : 'MCPOpenTelemetryHangingMetricReader',
	#superclass : 'OTInMemoryMetricReader',
	#instVars : [
		'gate',
		'entered'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'initialization' }
MCPOpenTelemetryHangingMetricReader >> initialize [

	super initialize.
	gate := Semaphore new.
	entered := false
]

{ #category : 'actions' }
MCPOpenTelemetryHangingMetricReader >> open [

	gate signal
]

{ #category : 'lifecycle' }
MCPOpenTelemetryHangingMetricReader >> shutdown [

	entered := true.
	gate waitTimeoutSeconds: 10.
	^ super shutdown
]

{ #category : 'testing' }
MCPOpenTelemetryHangingMetricReader >> wasEntered [

	^ entered
]
