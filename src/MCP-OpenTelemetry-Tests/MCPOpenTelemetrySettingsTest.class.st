"
Tests for how an image reads MCP's telemetry settings, from an environment given as a Dictionary and a settings file in a directory of its own.
"
Class {
	#name : 'MCPOpenTelemetrySettingsTest',
	#superclass : 'TestCase',
	#instVars : [
		'directory'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'running' }
MCPOpenTelemetrySettingsTest >> setUp [

	super setUp.
	directory := FileLocator temp asFileReference / ('mcp-otel-settings-' , UUID new asString).
	directory ensureCreateDirectory
]

{ #category : 'private' }
MCPOpenTelemetrySettingsTest >> settingsWith: anEnvironment fileText: aString [
	"Settings whose XDG_CONFIG_HOME is this test's directory, its file holding aString, or no file when aString is nil."

	anEnvironment at: 'XDG_CONFIG_HOME' put: directory fullName.
	aString ifNotNil: [
			(directory / 'pharo-mcp') ensureCreateDirectory.
			directory / 'pharo-mcp' / 'otel.env' writeStreamDo: [ :stream | stream nextPutAll: aString ] ].
	^ MCPOpenTelemetrySettings environment: anEnvironment
]

{ #category : 'running' }
MCPOpenTelemetrySettingsTest >> tearDown [

	directory ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTheFileGivesItsOTELSettingsAndNothingElse [

	| settings |
	self assert: (self settingsWith: Dictionary new fileText: nil) fileSettings isEmpty.
	settings := self settingsWith: Dictionary new fileText: '# Written by hand.

export OTEL_EXPORTER_OTLP_ENDPOINT = http://127.0.0.1:4318
OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer%20token"
OTEL_RESOURCE_ATTRIBUTES=''deployment.environment.name=field''
PATH=/somewhere/else
OTEL_lower=no
not a setting
'.
	self assert: settings fileSettings equals: (Dictionary newFrom: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'http://127.0.0.1:4318').
				 ('OTEL_EXPORTER_OTLP_HEADERS' -> 'authorization=Bearer%20token').
				 ('OTEL_RESOURCE_ATTRIBUTES' -> 'deployment.environment.name=field') })
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTheFileIsAppliedOnlyToAnEnvironmentWithoutSettingsOfItsOwn [

	| environment |
	environment := Dictionary new.
	(self settingsWith: environment fileText: 'OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318') apply.
	self assert: (environment at: 'OTEL_EXPORTER_OTLP_ENDPOINT') equals: 'http://127.0.0.1:4318'.

	environment := Dictionary newFrom: { ('OTEL_SERVICE_NAME' -> 'mine') }.
	(self settingsWith: environment fileText: 'OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318') apply.
	self deny: (environment includesKey: 'OTEL_EXPORTER_OTLP_ENDPOINT')
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTheFileIsInMCPsConfigurationDirectory [

	| home |
	home := FileLocator home asFileReference.
	self
		assert: (MCPOpenTelemetrySettings environment: (Dictionary newFrom: { ('XDG_CONFIG_HOME' -> '/config') })) settingsFile
		equals: '/config/pharo-mcp/otel.env' asFileReference.
	self
		assert: (MCPOpenTelemetrySettings environment: (Dictionary newFrom: { ('XDG_CONFIG_HOME' -> 'relative') })) settingsFile
		equals: home / '.config' / 'pharo-mcp' / 'otel.env'.
	self
		assert: ((MCPOpenTelemetrySettings environment: (Dictionary newFrom: { ('APPDATA' -> '/roaming') }))
				 windows: true;
				 settingsFile)
		equals: '/roaming/pharo-mcp/otel.env' asFileReference.
	self
		assert: (MCPOpenTelemetrySettings environment: (Dictionary newFrom: { ('APPDATA' -> '/roaming') })) settingsFile
		equals: home / '.config' / 'pharo-mcp' / 'otel.env'
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTracesAreAskedForByAnEndpointOrAConfigurationFile [

	| configured |
	configured := [ :pairs | (MCPOpenTelemetrySettings environment: (Dictionary newFrom: pairs)) isConfigured ].
	self deny: (configured value: #(  )).
	self assert: (configured value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test') }).
	self assert: (configured value: { ('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' -> 'https://c.test/v1/traces') }).
	self assert: (configured value: { ('OTEL_CONFIG_FILE' -> '/etc/otel.yaml') }).
	self assert: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_TRACES_EXPORTER' -> 'console, otlp') }).
	self deny: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_TRACES_EXPORTER' -> 'none') }).
	self deny: (configured value: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
				 ('OTEL_SDK_DISABLED' -> 'TRUE') }).
	self deny: (configured value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> '  ') })
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testTracesAskedForInTheFileAreAskedFor [

	| environment |
	environment := Dictionary new.
	self assert: (MCPOpenTelemetryObservabilityBackend wantsTraces:
			 (self settingsWith: environment fileText: 'OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318'))
]
