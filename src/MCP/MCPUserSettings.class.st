"
The files a user keeps for every MCP server they run, in MCP's folder of their configuration: $XDG_CONFIG_HOME/pharo-mcp when that is an absolute path, %APPDATA%\pharo-mcp on Windows, ~/.config/pharo-mcp otherwise.

Reads its environment through at:ifAbsent:, so a test gives it a Dictionary.
"
Class {
	#name : 'MCPUserSettings',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'windows',
		'home'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'instance creation' }
MCPUserSettings class >> current [
	"The settings of this image's process."

	^ self new
		  environment: OSEnvironment current;
		  windows: OSPlatform current isWindows;
		  home: self homeDirectory;
		  yourself
]

{ #category : 'accessing' }
MCPUserSettings class >> homeDirectory [
	"The user's home directory, or nil when the process cannot tell, as when HOME is unset: then there is no settings file to read there, which is no reason to fail."

	^ [ FileLocator home asFileReference ]
		  on: Error
		  do: [ :error | error return: nil ]
]

{ #category : 'instance creation' }
MCPUserSettings class >> withEnvironment: aDictionary [
	"Settings read from aDictionary instead of the process's environment, on a Unix-like system."

	^ self new
		  environment: aDictionary;
		  windows: false;
		  home: self homeDirectory;
		  yourself
]

{ #category : 'initialization' }
MCPUserSettings >> environment: aDictionary [

	environment := aDictionary
]

{ #category : 'accessing' }
MCPUserSettings >> fileNamed: aString [
	"The file of that name in MCP's folder of the user's configuration, or nil with no folder to find it in."

	^ self folder ifNotNil: [ :folder | folder / aString ]
]

{ #category : 'accessing' }
MCPUserSettings >> folder [
	"MCP's folder of the user's configuration: $XDG_CONFIG_HOME/pharo-mcp when that is an absolute path, %APPDATA%\pharo-mcp on Windows, ~/.config/pharo-mcp otherwise; nil with no home to find it in."

	| configHome appData |
	configHome := self valueAt: 'XDG_CONFIG_HOME'.
	(configHome isNotNil and: [ self isAbsolutePath: configHome ]) ifTrue: [ ^ configHome asFileReference / 'pharo-mcp' ].
	appData := self valueAt: 'APPDATA'.
	(windows and: [ appData isNotNil ]) ifTrue: [ ^ appData asFileReference / 'pharo-mcp' ].
	^ home ifNotNil: [ home / '.config' / 'pharo-mcp' ]
]

{ #category : 'initialization' }
MCPUserSettings >> home: aFileReference [

	home := aFileReference
]

{ #category : 'testing' }
MCPUserSettings >> isAbsolutePath: aString [
	"Whether Node, which writes these files for the tools that do, reads aString as an absolute path on this system: one that starts at the root, and on Windows also one that starts with a separator or a drive letter, a colon and a separator, either way round (C:\ or C:/)."

	aString isEmpty ifTrue: [ ^ false ].
	windows ifFalse: [ ^ aString first = $/ ].
	('/\' includes: aString first) ifTrue: [ ^ true ].
	^ aString size >= 3 and: [
		  aString first asInteger < 128 and: [
			  aString first isLetter and: [ (aString at: 2) = $: and: [ '/\' includes: (aString at: 3) ] ] ] ]
]

{ #category : 'private' }
MCPUserSettings >> textOf: aFile [
	"The file's text: UTF-8, or else its bytes as Latin-1, so that a byte an editor wrote in another encoding, as in a comment, does not cost the whole file."

	| bytes |
	bytes := aFile binaryReadStreamDo: [ :stream | stream upToEnd ].
	^ [ ZnCharacterEncoder utf8 decodeBytes: bytes ]
		  on: Error
		  do: [ :error | error return: bytes asString ]
]

{ #category : 'accessing' }
MCPUserSettings >> textOfFileNamed: aString [
	"The text of the file of that name, or nil when there is none or it cannot be read: a user's file never stops a server."

	| file |
	file := (self fileNamed: aString) ifNil: [ ^ nil ].
	^ [ self textOf: file ]
		  on: Error
		  do: [ :error | error return: nil ]
]

{ #category : 'accessing' }
MCPUserSettings >> valueAt: aName [
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
MCPUserSettings >> windows: aBoolean [

	windows := aBoolean
]
