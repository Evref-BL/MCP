"
A user's choice of advertised tools, read from tools.json in MCP's folder of their configuration: the tools it moves across a server's defaults, and what a server configured in code keeps.
"
Class {
	#name : 'MCPToolChoiceTest',
	#superclass : 'TestCase',
	#instVars : [
		'directory'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'running' }
MCPToolChoiceTest >> setUp [

	super setUp.
	directory := FileLocator temp asFileReference / ('mcp-tool-choice-' , UUID new asString).
	directory ensureCreateDirectory
]

{ #category : 'private' }
MCPToolChoiceTest >> settingsWithFile: aString [
	"User settings whose configuration folder is this test's directory, its tools.json holding aString, or no file when aString is nil."

	aString ifNotNil: [
			(directory / 'pharo-mcp') ensureCreateDirectory.
			directory / 'pharo-mcp' / 'tools.json' writeStreamDo: [ :stream | stream nextPutAll: aString ] ].
	^ MCPUserSettings withEnvironment: (Dictionary newFrom: { ('XDG_CONFIG_HOME' -> directory fullName) })
]

{ #category : 'running' }
MCPToolChoiceTest >> tearDown [

	directory ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
MCPToolChoiceTest >> testAChoiceMovesToolsAcrossTheDefaults [

	| registry |
	registry := MCPToolRegistry default.
	registry toolChoice: (MCPToolChoice advertise: #( 'repository_search' ) unadvertise: #( 'tool_search' )).
	self assert: (registry isToolAdvertisedNamed: 'repository_search').
	self deny: (registry isToolAdvertisedNamed: 'tool_search').
	self assert: (registry isToolAdvertisedNamed: 'class_get').
	self deny: (registry isToolAdvertisedNamed: 'method_update')
]

{ #category : 'tests' }
MCPToolChoiceTest >> testANameInBothListsKeepsItsDefault [

	| choice |
	choice := MCPToolChoice advertise: #( 'tool_search' 'repository_search' ) unadvertise: #( 'tool_search' 'repository_search' ).
	self assert: (choice advertisesToolNamed: 'tool_search' byDefault: true).
	self deny: (choice advertisesToolNamed: 'repository_search' byDefault: false)
]

{ #category : 'tests' }
MCPToolChoiceTest >> testANameNoToolHasIsSkipped [
	"The tool may come from a project this image does not load, or from another release."

	| registry |
	registry := MCPToolRegistry default.
	registry toolChoice: (MCPToolChoice advertise: #( 'no_such_tool' 'repository_search' ) unadvertise: #( 'another_missing_tool' )).
	self assert: (registry isToolAdvertisedNamed: 'repository_search').
	self deny: (registry advertisedToolNames includes: 'no_such_tool')
]

{ #category : 'tests' }
MCPToolChoiceTest >> testAServerConfiguredInCodeKeepsItsTools [
	"The choice changes the defaults, so a server whose code chose its tools keeps them."

	| registry |
	registry := MCPToolRegistry default.
	registry toolChoice: (MCPToolChoice advertise: #( 'repository_search' ) unadvertise: #( 'class_get' )).
	registry advertiseTools: #( 'class_get' ).
	self assert: registry advertisedToolNames equals: #( 'class_get' ).
	registry advertiseAllTools.
	self assert: (registry isToolAdvertisedNamed: 'class_get')
]

{ #category : 'tests' }
MCPToolChoiceTest >> testAToolAdvertisedInCodeKeepsTheChoice [
	"advertiseTool: adds one tool to what is advertised, the user's choice included."

	| registry |
	registry := MCPToolRegistry default.
	registry toolChoice: (MCPToolChoice advertise: #( 'repository_search' ) unadvertise: #( 'tool_search' )).
	registry advertiseTool: 'method_update'.
	self assert: (registry isToolAdvertisedNamed: 'repository_search').
	self deny: (registry isToolAdvertisedNamed: 'tool_search').
	self assert: (registry isToolAdvertisedNamed: 'method_update')
]

{ #category : 'tests' }
MCPToolChoiceTest >> testTheFileGivesTheChoice [

	| choice |
	choice := MCPToolChoice of: (self settingsWithFile: '{ "advertise": ["test_coverage_run"], "unadvertise": ["critique_run"] }').
	self assert: (choice advertisesToolNamed: 'test_coverage_run' byDefault: false).
	self deny: (choice advertisesToolNamed: 'critique_run' byDefault: true).
	self assert: (choice advertisesToolNamed: 'class_get' byDefault: true)
]

{ #category : 'tests' }
MCPToolChoiceTest >> testTheFileIsReadLeniently [
	"A single name for a list, blanks around a name, entries that are not names, and keys it does not know."

	| choice |
	choice := MCPToolChoice of:
		          (self settingsWithFile:
			           '{ "advertise": " test_coverage_run ", "unadvertise": ["critique_run", 3, null, ""], "comment": "mine" }').
	self assert: (choice advertisesToolNamed: 'test_coverage_run' byDefault: false).
	self deny: (choice advertisesToolNamed: 'critique_run' byDefault: true).
	self assert: (choice advertisesToolNamed: 'class_get' byDefault: true)
]

{ #category : 'tests' }
MCPToolChoiceTest >> testTheFilesAreInMCPsConfigurationFolder [

	| home |
	home := FileLocator home asFileReference.
	self
		assert: ((MCPUserSettings withEnvironment: (Dictionary newFrom: { ('XDG_CONFIG_HOME' -> '/config') })) fileNamed: 'tools.json')
		equals: '/config/pharo-mcp/tools.json' asFileReference.
	self
		assert: ((MCPUserSettings withEnvironment: (Dictionary newFrom: { ('XDG_CONFIG_HOME' -> 'relative') })) fileNamed: 'tools.json')
		equals: home / '.config' / 'pharo-mcp' / 'tools.json'.
	self
		assert: (((MCPUserSettings withEnvironment: (Dictionary newFrom: { ('APPDATA' -> '/roaming') }))
				  windows: true;
				  yourself) fileNamed: 'tools.json')
		equals: '/roaming/pharo-mcp/tools.json' asFileReference
]

{ #category : 'tests' }
MCPToolChoiceTest >> testWithoutAHomeNothingIsRead [
	"HOME may be unset, as in a service or a container: then there is no file to read."

	| settings |
	settings := (MCPUserSettings withEnvironment: Dictionary new)
		            home: nil;
		            yourself.
	self assert: (settings fileNamed: 'tools.json') isNil.
	self assert: ((MCPToolChoice of: settings) advertisesToolNamed: 'class_get' byDefault: true)
]

{ #category : 'tests' }
MCPToolChoiceTest >> testWithoutAUsableFileNothingChanges [
	"No file, an empty one, one that is not JSON, and JSON that holds no lists of names."

	#( nil '' 'not json' '[ "class_get" ]' '{ "advertise": { "repository_search": true } }' ) do: [ :text |
			| choice |
			choice := MCPToolChoice of: (self settingsWithFile: text).
			self assert: (choice advertisesToolNamed: 'class_get' byDefault: true) description: text printString.
			self deny: (choice advertisesToolNamed: 'repository_search' byDefault: false) description: text printString ]
]
