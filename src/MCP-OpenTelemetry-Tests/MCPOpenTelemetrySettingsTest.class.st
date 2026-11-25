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
MCPOpenTelemetrySettingsTest >> testACommentAfterAValueIsNotPartOfIt [
	"As a dotenv file reads: a # that starts the value or follows a space or tab starts a comment, unless quotes hold it."

	self
		assert: (self settingsWith: Dictionary new fileText: 'OTEL_TRACES_EXPORTER = otlp # the default
OTEL_EXPORTER_OTLP_HEADERS="key=a#b" # quoted
OTEL_SERVICE_NAME=a#b
OTEL_LOG_LEVEL=	# nothing
OTEL_PROPAGATORS=''tracecontext # baggage''
OTEL_SDK_DISABLED="false" and more
') fileSettings
		equals: (Dictionary newFrom: {
					 ('OTEL_TRACES_EXPORTER' -> 'otlp').
					 ('OTEL_EXPORTER_OTLP_HEADERS' -> 'key=a#b').
					 ('OTEL_SERVICE_NAME' -> 'a#b').
					 ('OTEL_LOG_LEVEL' -> '').
					 ('OTEL_PROPAGATORS' -> 'tracecontext # baggage').
					 ('OTEL_SDK_DISABLED' -> '"false" and more') })
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testAFileThatIsNotUTF8IsReadAllTheSame [
	"A byte another encoding wrote, here an é in Latin-1 in a comment, leaves the rest of the file read."

	| settings |
	settings := self settingsWith: Dictionary new fileText: nil.
	(directory / 'pharo-mcp') ensureCreateDirectory.
	directory / 'pharo-mcp' / 'otel.env' binaryWriteStreamDo: [ :stream |
			stream
				nextPutAll: '# caf' asByteArray;
				nextPut: 16rE9;
				nextPutAll: ' agent' asByteArray;
				nextPut: 10;
				nextPutAll: 'OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318' asByteArray;
				nextPut: 10 ].
	self assert: settings fileSettings equals: (Dictionary newFrom: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'http://127.0.0.1:4318') })
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testContentIsAskedForOnTheSpanAsTheGenAIConventionsSay [

	| captures |
	captures := [ :value |
		            (MCPOpenTelemetrySettings environment:
			             (Dictionary newFrom:
				              (value ifNil: [ #(  ) ] ifNotNil: [ { ('OTEL_INSTRUMENTATION_GENAI_CAPTURE_CONTENT' -> value) } ])))
			            capturesContent ].
	self deny: (captures value: nil).
	self assert: (captures value: 'SPAN_ONLY').
	self assert: (captures value: ' span_and_event ').
	self deny: (captures value: 'EVENT_ONLY').
	self deny: (captures value: 'NO_CONTENT').
	self deny: (captures value: 'true')
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testEachSignalIsAskedForByItsExporterAndAnEndpoint [
	"A signal goes where its own endpoint, or the one the signals share, says, when its exporter is OTLP, the default; a configuration file says where each goes. A signal with no endpoint goes nowhere."

	| signals |
	signals := [ :pairs | (MCPOpenTelemetrySettings environment: (Dictionary newFrom: pairs)) signals asArray ].
	self assert: (signals value: #(  )) equals: #(  ).
	self assert: (signals value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test') }) equals: #( #traces #metrics #logs ).
	self assert: (signals value: { ('OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' -> 'https://c.test/v1/traces') }) equals: #( #traces ).
	self assert: (signals value: { ('OTEL_EXPORTER_OTLP_METRICS_ENDPOINT' -> 'https://c.test/v1/metrics') }) equals: #( #metrics ).
	self assert: (signals value: { ('OTEL_EXPORTER_OTLP_LOGS_ENDPOINT' -> 'https://c.test/v1/logs') }) equals: #( #logs ).
	self assert: (signals value: { ('OTEL_CONFIG_FILE' -> '/etc/otel.yaml') }) equals: #( #traces #metrics #logs ).
	self
		assert: (signals value: {
					 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
					 ('OTEL_TRACES_EXPORTER' -> 'console, otlp').
					 ('OTEL_METRICS_EXPORTER' -> 'none').
					 ('OTEL_LOGS_EXPORTER' -> 'console') })
		equals: #( #traces ).
	self
		assert: (signals value: {
					 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'https://c.test').
					 ('OTEL_SDK_DISABLED' -> 'TRUE') })
		equals: #(  ).
	self assert: (signals value: { ('OTEL_EXPORTER_OTLP_ENDPOINT' -> '  ') }) equals: #(  )
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testOnWindowsAConfigurationHomeWithADriveIsAbsolute [
	"As Node reads it, so MCP looks where a tool written for Node wrote the file."

	| windows |
	windows := (MCPOpenTelemetrySettings environment: Dictionary new)
		           windows: true;
		           yourself.
	#( 'C:/Users/me/.config' 'c:\Users\me\.config' '\\server\share' '/config' ) do: [ :each |
		self assert: (windows isAbsolutePath: each) description: each ].
	#( 'relative' 'C:relative' 'C:' '' ) do: [ :each | self deny: (windows isAbsolutePath: each) description: each ].
	self deny: ((MCPOpenTelemetrySettings environment: Dictionary new) isAbsolutePath: 'C:/Users/me/.config').
	self
		assert: ((MCPOpenTelemetrySettings environment: (Dictionary newFrom: {
								   ('XDG_CONFIG_HOME' -> 'C:/Users/me/.config').
								   ('APPDATA' -> '/roaming') }))
				 windows: true;
				 settingsFile)
		equals: 'C:/Users/me/.config' asFileReference / 'pharo-mcp' / 'otel.env'
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testSignalsAskedForInTheFileAreAskedFor [

	| environment |
	environment := Dictionary new.
	self
		assert: (MCPOpenTelemetryObservabilityBackend signalsAskedForBy:
				 (self settingsWith: environment fileText: 'OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://127.0.0.1:4318/v1/metrics'))
		equals: #( #metrics )
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
MCPOpenTelemetrySettingsTest >> testTheFilesSettingsReplaceEveryOneTheEnvironmentHas [
	"The program that starts the image may pass down its own OTEL_* variables, as an agent host monitored with OpenTelemetry does: MCP's own file says where MCP's telemetry goes."

	| environment |
	environment := Dictionary newFrom: {
			               ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'http://collector.test:4317').
			               ('OTEL_EXPORTER_OTLP_PROTOCOL' -> 'grpc').
			               ('PATH' -> '/bin') }.
	(self settingsWith: environment fileText: 'OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318') apply.
	self assert: environment equals: (Dictionary newFrom: {
				 ('OTEL_EXPORTER_OTLP_ENDPOINT' -> 'http://127.0.0.1:4318').
				 ('PATH' -> '/bin').
				 ('XDG_CONFIG_HOME' -> directory fullName) })
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testWithoutAHomeThereIsNoSettingsFileAndNoError [
	"HOME may be unset, as in a service or a container: then there is no file to read there."

	| settings environment previous |
	settings := (MCPOpenTelemetrySettings environment: Dictionary new)
		            home: nil;
		            yourself.
	self assert: settings settingsFile isNil.
	self assert: settings fileSettings isEmpty.
	self assert: settings apply isEmpty.
	OSPlatform current isWindows ifTrue: [ ^ self ].
	environment := OSEnvironment current.
	previous := environment at: 'HOME' ifAbsent: [ nil ].
	[
		environment removeKey: 'HOME'.
		self shouldnt: [ MCPOpenTelemetrySettings current fileSettings ] raise: Error ] ensure: [
		previous ifNotNil: [ environment at: 'HOME' put: previous ] ]
]

{ #category : 'tests' }
MCPOpenTelemetrySettingsTest >> testWithoutSettingsInAFileTheEnvironmentDecides [

	#( nil '# Nothing set.
PATH=/elsewhere' ) do: [ :text |
			| environment |
			environment := Dictionary newFrom: { ('OTEL_SERVICE_NAME' -> 'mine') }.
			self assert: (self settingsWith: environment fileText: text) apply isEmpty.
			self assert: environment equals: (Dictionary newFrom: {
						 ('OTEL_SERVICE_NAME' -> 'mine').
						 ('XDG_CONFIG_HOME' -> directory fullName) }) ]
]
