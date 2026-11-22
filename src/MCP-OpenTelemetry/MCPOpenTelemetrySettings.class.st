"
MCP's telemetry settings, as an image reads them: MCP's own settings file, whose settings replace every OTEL_* variable the image inherited, so that whoever wrote it decides where MCP's telemetry goes whatever program started the image; or else, with no file or a file that gives none, the OTEL_* environment.

Reads its environment through at:ifAbsent: and keys, and writes it through at:put: and removeKey:, so a test gives it a Dictionary.
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
		  home: self homeDirectory;
		  yourself
]

{ #category : 'instance creation' }
MCPOpenTelemetrySettings class >> environment: aDictionary [
	"Settings read from aDictionary instead of the process's environment, on a Unix-like system."

	^ self new
		  environment: aDictionary;
		  windows: false;
		  home: self homeDirectory;
		  yourself
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings class >> homeDirectory [
	"The user's home directory, or nil when the process cannot tell, as when HOME is unset: then there is no settings file to read there, which is no reason to fail."

	^ [ FileLocator home asFileReference ]
		  on: Error
		  do: [ :error | error return: nil ]
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

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> environment: aDictionary [

	environment := aDictionary
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> fileSettings [
	"The OTEL_* settings the file's KEY=value lines give, as a dotenv file writes them. Blank lines and # comments are skipped, as are a leading export, a # comment after a value, and quotes around a value; any other key is not the file's to set. No file gives none."

	| settings contents |
	settings := Dictionary new.
	contents := [ (self settingsFile ifNil: [ ^ settings ]) contents ]
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

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> home: aFileReference [

	home := aFileReference
]

{ #category : 'testing' }
MCPOpenTelemetrySettings >> isAbsolutePath: aString [
	"Whether Node, which writes this file for the tools that do, reads aString as an absolute path on this system: one that starts at the root, and on Windows also one that starts with a separator or a drive letter, a colon and a separator, either way round (C:\ or C:/)."

	aString isEmpty ifTrue: [ ^ false ].
	windows ifFalse: [ ^ aString first = $/ ].
	('/\' includes: aString first) ifTrue: [ ^ true ].
	^ aString size >= 3 and: [
		  aString first asInteger < 128 and: [
			  aString first isLetter and: [ (aString at: 2) = $: and: [ '/\' includes: (aString at: 3) ] ] ] ]
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
MCPOpenTelemetrySettings >> settingNamesInEnvironment [
	"The OTEL_* variables the environment sets."

	^ [ (environment keys select: [ :each | each asString beginsWith: 'OTEL_' ]) asArray ]
		  on: Error
		  do: [ :error | error return: #(  ) ]
]

{ #category : 'accessing' }
MCPOpenTelemetrySettings >> settingsFile [
	"Where MCP's settings live: $XDG_CONFIG_HOME/pharo-mcp/otel.env when that is an absolute path, %APPDATA%\pharo-mcp\otel.env on Windows, ~/.config/pharo-mcp/otel.env otherwise; nil with no home to find it in."

	| configHome appData |
	configHome := self valueAt: 'XDG_CONFIG_HOME'.
	(configHome isNotNil and: [ self isAbsolutePath: configHome ]) ifTrue: [ ^ configHome asFileReference / 'pharo-mcp' / 'otel.env' ].
	appData := self valueAt: 'APPDATA'.
	(windows and: [ appData isNotNil ]) ifTrue: [ ^ appData asFileReference / 'pharo-mcp' / 'otel.env' ].
	^ home ifNotNil: [ home / '.config' / 'pharo-mcp' / 'otel.env' ]
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

{ #category : 'initialization' }
MCPOpenTelemetrySettings >> windows: aBoolean [

	windows := aBoolean
]
