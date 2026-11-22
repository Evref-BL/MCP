"
MCP's telemetry settings, as an image reads them: the OTEL_* environment, or else MCP's own settings file, for an image whose environment its user does not control, such as one started from a launcher's window.

Reads its environment through at:ifAbsent: and keys, and writes it through at:put:, so a test gives it a Dictionary.
"
Class {
	#name : 'MCPOpenTelemetrySettings',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'windows',
		'home'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> current [
	"The settings of this image's process."

	^ self new
		  environment: OSEnvironment current;
		  windows: OSPlatform current isWindows;
		  home: FileLocator home asFileReference;
		  yourself
]

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> environment: aDictionary [
	"Settings read from aDictionary instead of the process's environment, on a Unix-like system."

	^ self new
		  environment: aDictionary;
		  windows: false;
		  home: FileLocator home asFileReference;
		  yourself
]

{ #category : 'applying' }
MCPOpenTelemetrySettings >> apply [
	"Puts the file's settings into the environment, where the OpenTelemetry SDK reads them, unless the environment has settings of its own. Answers what it set."

	| settings |
	self hasOwnSettings ifTrue: [ ^ Dictionary new ].
	settings := self fileSettings.
	settings keysAndValuesDo: [ :key :value | environment at: key put: value ].
	^ settings
]

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> environment: aDictionary [

	environment := aDictionary
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> fileSettings [
	"The OTEL_* settings the file's KEY=value lines give. Blank lines and # comments are skipped, as are a leading export and quotes around a value; any other key is not the file's to set. No file gives none."

	| settings contents |
	settings := Dictionary new.
	contents := [ self settingsFile contents ]
		            on: Error
		            do: [ ^ settings ].
	contents lines do: [ :raw |
			| line equals key value |
			line := raw trimBoth.
			(line beginsWith: 'export ') ifTrue: [ line := (line allButFirst: 7) trimBoth ].
			equals := line indexOf: $=.
			(line isNotEmpty and: [ line first ~= $# and: [ equals > 1 ] ]) ifTrue: [
					key := (line first: equals - 1) trimBoth.
					value := (line allButFirst: equals) trimBoth.
					(value size >= 2 and: [ ('"''' includes: value first) and: [ value last = value first ] ]) ifTrue: [
						value := value copyFrom: 2 to: value size - 1 ].
					(self isSettingName: key) ifTrue: [ settings at: key put: value ] ] ].
	^ settings
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> hasOwnSettings [
	"Whether the environment sets any OTEL_* variable: whoever set one there meant the environment to decide."

	^ [ environment keys anySatisfy: [ :each | each asString beginsWith: 'OTEL_' ] ]
		  on: Error
		  do: [ false ]
]

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> home: aFileReference [

	home := aFileReference
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

{ #category : 'testing' }
MCPOpenTelemetrySettings >> isSettingName: aString [

	^ (aString beginsWith: 'OTEL_') and: [
		  aString size > 5 and: [ aString allSatisfy: [ :each | each isUppercase or: [ each isDigit or: [ each = $_ ] ] ] ] ]
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> settingsFile [
	"Where MCP's settings live: $XDG_CONFIG_HOME/pharo-mcp/otel.env, %APPDATA%\pharo-mcp\otel.env on Windows, ~/.config/pharo-mcp/otel.env otherwise."

	| configHome appData |
	configHome := self valueAt: 'XDG_CONFIG_HOME'.
	(configHome isNotNil and: [ (Path from: configHome) isAbsolute ]) ifTrue: [
		^ configHome asFileReference / 'pharo-mcp' / 'otel.env' ].
	appData := self valueAt: 'APPDATA'.
	(windows and: [ appData isNotNil ]) ifTrue: [ ^ appData asFileReference / 'pharo-mcp' / 'otel.env' ].
	^ home / '.config' / 'pharo-mcp' / 'otel.env'
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

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> windows: aBoolean [

	windows := aBoolean
]
