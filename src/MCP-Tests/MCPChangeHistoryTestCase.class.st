"
Common base class for tests that read back the change history they write. A test logs what it changes to a history of its own, through the monitor logTo: puts in place of the empty one runCase gives it, and tearDown stops that monitor, which would otherwise go on logging, and deletes the directory logDirectoryIn: made.
"
Class {
	#name : 'MCPChangeHistoryTestCase',
	#superclass : 'MCPToolAPITestCase',
	#instVars : [
		'logDirectory'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPChangeHistoryTestCase class >> isAbstract [

	^ self = MCPChangeHistoryTestCase or: [ super isAbstract ]
]

{ #category : 'testing' }
MCPChangeHistoryTestCase class >> shouldLogWithEpicea [
	"Epicea leaves out of the history what a test changes unless the test says otherwise, and these tests read it back."

	^ true
]

{ #category : 'private - history' }
MCPChangeHistoryTestCase >> logDirectoryIn: aDirectory [
	"A directory of the test's own for its history, which tearDown deletes."

	^ logDirectory := (aDirectory / ('mcp-test-history-' , UUID new asString36)) ensureCreateDirectory
]

{ #category : 'private - history' }
MCPChangeHistoryTestCase >> logTo: aLog [
	"What the test changes from here on goes to aLog, through a monitor of the test's own in place of the one before it."

	EpMonitor current disable.
	EpMonitor current: (EpMonitor newWithLog: aLog).
	EpMonitor current enable
]

{ #category : 'private - history' }
MCPChangeHistoryTestCase >> logToASessionStore [
	"As the image's monitor does, which restart moves to a new file. It is on disk, since a session store needs a file system that says it is writable, which a memory one does not."

	self logTo: (EpLog newWithStore: (OmSessionStore newWithBaseLocator: (self logDirectoryIn: FileLocator temp asFileReference)))
]

{ #category : 'private - history' }
MCPChangeHistoryTestCase >> restart [
	"Save the image at the session's last entry and start it again: the next session is a new file, which has logged nothing yet and continues from that entry."

	EpMonitor current sessionStore
		flush;
		resetWithNextStoreName
]

{ #category : 'running' }
MCPChangeHistoryTestCase >> tearDown [
	"runCase puts the image's monitor back, but the test's own goes on logging until it is disabled."

	EpMonitor current disable.
	logDirectory ifNotNil: [ logDirectory ensureDeleteAll ].
	super tearDown
]
