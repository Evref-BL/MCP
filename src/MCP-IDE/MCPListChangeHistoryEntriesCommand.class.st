"
Reads the entries of a change history, from the session in progress or from a named .ombu file, keeping the code changes only when asked and the newest first when asked.

execute answers each entry with its one-based index; log and historyFileName then say where they were read from.
"
Class {
	#name : 'MCPListChangeHistoryEntriesCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#instVars : [
		'directoryPath',
		'historyFile',
		'codeChangesOnly',
		'newestFirst',
		'log',
		'historyFileName'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPListChangeHistoryEntriesCommand class >> directoryPath: aPathString historyFile: aFileName codeChangesOnly: codeChangesOnlyBoolean newestFirst: newestFirstBoolean [
	"aPathString and aFileName name a .ombu file, or are nil for the directory holding this image's history and the session in progress."

	^ self new
		  directoryPath: aPathString;
		  historyFile: aFileName;
		  codeChangesOnly: codeChangesOnlyBoolean;
		  newestFirst: newestFirstBoolean;
		  yourself
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> codeChangesOnly: aBoolean [

	codeChangesOnly := aBoolean
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> directoryPath: aPathString [

	directoryPath := aPathString
]

{ #category : 'execution' }
MCPListChangeHistoryEntriesCommand >> execute [
	"Answer the entries of the history as pairs of their one-based index and the entry, the oldest first unless newestFirst."

	| logAndFileName |
	logAndFileName := self logAndFileNameFromDirectoryPath: directoryPath fileName: historyFile.
	log := logAndFileName first.
	historyFileName := logAndFileName second.
	^ self matchingEntryPairsFrom: log
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> historyFile: aFileName [

	historyFile := aFileName
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> historyFileName [
	"The name of the file execute read the entries from, nil when the session in progress has none."

	^ historyFileName
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> log [
	"The log execute read the entries from."

	^ log
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> matchingEntryPairsFrom: aLog [

	| pairs |
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
			(codeChangesOnly not or: [ self isCodeChangeEntry: entry ]) ifTrue: [
					pairs add: {
							index.
							entry } ] ].
	newestFirst ifTrue: [ ^ pairs reversed asOrderedCollection ].
	^ pairs
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> newestFirst: aBoolean [

	newestFirst := aBoolean
]
