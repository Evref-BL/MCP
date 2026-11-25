"
MCP's telemetry settings, as an image reads them: otel.env in MCP's folder of the user's configuration, whose settings replace every OTEL_* variable the image inherited, so that whoever wrote it decides where MCP's telemetry goes whatever program started the image; or else, with no file or a file that gives none, the OTEL_* environment.

Reads its environment through at:ifAbsent: and keys, and writes it through at:put: and removeKey:, so a test gives it a Dictionary.
"
Class {
	#name : 'MCPOpenTelemetrySettings',
	#superclass : 'MCPUserSettings',
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> environment: aDictionary [
	"Settings read from aDictionary instead of the process's environment, on a Unix-like system."

	^ self withEnvironment: aDictionary
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings class >> signalNames [
	"The signals OpenTelemetry exports, each configured by its own variables."

	^ #( #traces #metrics #logs )
]

{ #category : 'applying' }
MCPOpenTelemetrySettings >> apply [
	"Puts the file's settings into the environment, where the OpenTelemetry SDK reads them, in place of every OTEL_* variable the process inherited: whoever wrote MCP's own file chose where its telemetry goes, whatever the program that started the image passes down. With no file, or a file that gives none, the environment decides. Answers what it set."

	| settings |
	settings := self fileSettings.
	settings ifEmpty: [ ^ settings ].
	self settingNamesInEnvironment do: [ :each |
			[ environment removeKey: each ]
				on: Error
				do: [ :error | error return: nil ] ].
	settings keysAndValuesDo: [ :key :value | environment at: key put: value ].
	^ settings
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> capturesContent [
	"Whether the settings ask for a tool call's arguments and result on its span, as OTEL_INSTRUMENTATION_GENAI_CAPTURE_CONTENT does for the OpenTelemetry conventions for GenAI: SPAN_ONLY or SPAN_AND_EVENT, in any case. Its default, NO_CONTENT, EVENT_ONLY and any other value do not."

	^ #( 'SPAN_ONLY' 'SPAN_AND_EVENT' ) includes:
		  ((self valueAt: 'OTEL_INSTRUMENTATION_GENAI_CAPTURE_CONTENT') ifNil: [ '' ]) asUppercase
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> fileSettings [
	"The OTEL_* settings the file's KEY=value lines give, as a dotenv file writes them. Blank lines and # comments are skipped, as are a leading export, a # comment after a value, and quotes around a value; any other key is not the file's to set. No file gives none."

	| settings contents |
	settings := Dictionary new.
	contents := [ self textOf: (self settingsFile ifNil: [ ^ settings ]) ]
		            on: Error
		            do: [ :error | ^ settings ].
	contents lines do: [ :raw |
			| line equals key |
			line := raw trimBoth.
			((line beginsWith: 'export') and: [ line size > 6 and: [ (line at: 7) isSeparator ] ]) ifTrue: [
				line := (line allButFirst: 6) trimBoth ].
			equals := line indexOf: $=.
			(line isNotEmpty and: [ line first ~= $# and: [ equals > 1 ] ]) ifTrue: [
					key := (line first: equals - 1) trimBoth.
					(self isSettingName: key) ifTrue: [ settings at: key put: (self valueIn: (line allButFirst: equals)) ] ] ].
	^ settings
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> isConfiguredFor: aSignal [
	"Whether the settings ask for aSignal, one of signalNames, to be exported: the SDK is not disabled, and either a configuration file is named, which then says where each signal goes, or the signal's exporter is OTLP, the default, with an endpoint, its own or the one the signals share. A signal without one goes nowhere, not even to the SDK's default endpoint."

	| name exporters |
	((self valueAt: 'OTEL_SDK_DISABLED') ifNil: [ '' ]) asLowercase = 'true' ifTrue: [ ^ false ].
	(self valueAt: 'OTEL_CONFIG_FILE') ifNotNil: [ ^ true ].
	name := aSignal asString asUppercase.
	exporters := (((self valueAt: ('OTEL_{1}_EXPORTER' format: { name })) ifNil: [ '' ]) substrings: ',') collect: [ :each |
		             each trimBoth asLowercase ].
	(exporters isNotEmpty and: [ (exporters includes: 'otlp') not ]) ifTrue: [ ^ false ].
	^ (self valueAt: ('OTEL_EXPORTER_OTLP_{1}_ENDPOINT' format: { name })) isNotNil or: [
		  (self valueAt: 'OTEL_EXPORTER_OTLP_ENDPOINT') isNotNil ]
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> isSettingName: aString [

	^ (aString beginsWith: 'OTEL_') and: [
		  aString size > 5 and: [ aString allSatisfy: [ :each | each isUppercase or: [ each isDigit or: [ each = $_ ] ] ] ] ]
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> settingNamesInEnvironment [
	"The OTEL_* variables the environment sets."

	^ [ (environment keys select: [ :each | each asString beginsWith: 'OTEL_' ]) asArray ]
		  on: Error
		  do: [ :error | error return: #(  ) ]
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> settingsFile [
	"Where MCP's telemetry settings live: otel.env in MCP's folder of the user's configuration; nil with no home to find it in."

	^ self fileNamed: 'otel.env'
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> settingsInEffect [
	"The OTEL_* variables the environment sets, with their values: what OpenTelemetry's providers are made from."

	^ (self settingNamesInEnvironment collect: [ :each | each asString -> (self valueAt: each) ]) asDictionary
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> signals [
	"The signals the settings ask to be exported, each as its own variables say."

	^ self class signalNames select: [ :each | self isConfiguredFor: each ]
]

{ #category : 'private' }
MCPOpenTelemetrySettings >> valueIn: aString [
	"The value a line gives after its =: what quotes hold, # included, when a quote closes and nothing but a comment follows; otherwise the text before a # that starts it or follows a space or tab."

	| value end rest comment |
	value := aString trimBoth.
	(value isNotEmpty and: [ '"''' includes: value first ]) ifTrue: [
			end := value indexOf: value first startingAt: 2.
			end > 0 ifTrue: [
					rest := value allButFirst: end.
					(rest trimBoth isEmpty or: [ rest first isSeparator and: [ rest trimBoth first = $# ] ]) ifTrue: [
						^ value copyFrom: 2 to: end - 1 ] ] ].
	comment := (1 to: value size)
		           detect: [ :index | (value at: index) = $# and: [ index = 1 or: [ (value at: index - 1) isSeparator ] ] ]
		           ifNone: [ ^ value ].
	^ (value first: comment - 1) trimBoth
]
