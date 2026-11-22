"
The OTEL_* environment, as an image reads it to decide whether to record traces. The OpenTelemetry SDK reads the same variables to configure itself.

Reads its environment through at:ifAbsent:, so a test gives it a Dictionary.
"
Class {
	#name : 'MCPOpenTelemetrySettings',
	#superclass : 'Object',
	#instVars : [
		'environment'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> current [
	"The settings of this image's process."

	^ self environment: OSEnvironment current
]

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> environment: aDictionary [
	"Settings read from aDictionary instead of the process's environment."

	^ self new
		  environment: aDictionary;
		  yourself
]

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> environment: aDictionary [

	environment := aDictionary
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> isConfigured [
	"Whether the settings ask for traces to be exported: the SDK is not disabled, and either a configuration file is named or the traces exporter is OTLP, the default, with an endpoint."

	| exporters |
	((self valueAt: 'OTEL_SDK_DISABLED') ifNil: [ '' ]) asLowercase = 'true' ifTrue: [ ^ false ].
	(self valueAt: 'OTEL_CONFIG_FILE') ifNotNil: [ ^ true ].
	exporters := (((self valueAt: 'OTEL_TRACES_EXPORTER') ifNil: [ '' ]) substrings: ',') collect: [ :each |
		             each trimBoth asLowercase ].
	(exporters isNotEmpty and: [ (exporters includes: 'otlp') not ]) ifTrue: [ ^ false ].
	^ (self valueAt: 'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT') isNotNil or: [ (self valueAt: 'OTEL_EXPORTER_OTLP_ENDPOINT') isNotNil ]
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> valueAt: aName [
	"The variable's value, trimmed, or nil when it is unset or blank."

	| value |
	value := [ environment at: aName ifAbsent: [ nil ] ]
		         on: Error
		         do: [ nil ].
	value ifNil: [ ^ nil ].
	value := value asString trimBoth.
	^ value ifEmpty: [ nil ]
]
