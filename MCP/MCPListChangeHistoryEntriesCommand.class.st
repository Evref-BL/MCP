"
Command that lists granular entries from image change history.
"
Class {
	#name : 'MCPListChangeHistoryEntriesCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPListChangeHistoryEntriesCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> currentHistoryFileReference [

	| store lowLevel |
	EpMonitor hasCurrent ifFalse: [ ^ nil ].
	EpMonitor current sessionStore flush.
	store := EpMonitor current log store.
	(store respondsTo: #writingFileReference) ifTrue: [
		^ store writingFileReference ].
	(store respondsTo: #lowLevelFileStoreIfNone:) ifFalse: [ ^ nil ].
	lowLevel := store lowLevelFileStoreIfNone: [ nil ].
	(lowLevel notNil and: [ lowLevel respondsTo: #writingFileReference ])
		ifTrue: [ ^ lowLevel writingFileReference ].
	^ nil
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> currentLogAndPath [

	| log currentFile path |
	EpMonitor hasCurrent ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryUnavailable
			message: 'No current Pharo change history monitor is available.'
			details: Dictionary new ].
	EpMonitor current sessionStore flush.
	log := EpMonitor current log.
	log refresh.
	currentFile := self currentHistoryFileReference.
	path := currentFile ifNotNil: [ currentFile fullName ].
	^ {
		  log.
		  path }
]

{ #category : 'execution' }
MCPListChangeHistoryEntriesCommand >> execute [

	| logAndPath log path pairs page entryInfos headReference |
	logAndPath := self logAndPathForRequest.
	log := logAndPath first.
	path := logAndPath second.
	pairs := self matchingEntryPairsFrom: log.
	page := self
		        pageFrom: pairs
		        offset: request offset
		        limit: request limit.
	entryInfos := page collect: [ :pair |
		              MCPChangeHistoryEntryInfo
			              fromEntry: pair second
			              index: pair first
			              log: log ].
	headReference := self referenceStringFor: ([ log headReference ]
			                  on: Error
			                  do: [ :error | nil ]).
	^ MCPChangeHistoryListEntriesResult
		  historyFilePath: path
		  entries: entryInfos
		  totalCount: pairs size
		  limit: request limit
		  offset: request offset
		  newestFirst: request newestFirst
		  codeChangesOnly: request codeChangesOnly
		  headReference: headReference
]

{ #category : 'initialization' }
MCPListChangeHistoryEntriesCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> isCodeChangeEntry: anEntry [

	| content |
	content := [ anEntry content ]
		           on: Error
		           do: [ :error | nil ].
	^ content notNil and: [
		  (content respondsTo: #isCodeChange) and: [ content isCodeChange ] ]
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> logAndPathForRequest [

	request historyFilePath ifNil: [ ^ self currentLogAndPath ].
	^ self logAndPathFromFilePath: request historyFilePath
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> logAndPathFromFilePath: aPathString [

	| file log |
	file := aPathString asFileReference.
	file exists ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryFileNotFound
			message: 'Change history file ' , aPathString , ' does not exist.'
			details: { (#historyFilePath -> aPathString) } asDictionary ].
	file isFile ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryPathNotFile
			message: 'Change history path ' , aPathString , ' is not a file.'
			details: { (#historyFilePath -> aPathString) } asDictionary ].
	log := [
	       | loadedLog |
	       loadedLog := EpLog freshFromFile: file.
	       loadedLog entries size.
	       loadedLog ]
		       on: Error
		       do: [ :error |
			       MCPCommandError
				       signalErrorCode: #ChangeHistoryFileUnreadable
				       message:
				       'Change history file ' , file fullName
				       , ' could not be loaded.'
				       details: {
						       (#historyFilePath -> file fullName).
						       (#causeClass -> error class name).
						       (#causeMessage
						        -> (error messageText ifNil: [ error asString ])) }
						       asDictionary ].
	^ {
		  log.
		  file fullName }
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> matchingEntryPairsFrom: aLog [

	| pairs |
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
		(request codeChangesOnly not or: [ self isCodeChangeEntry: entry ])
			ifTrue: [
				pairs add: {
						index.
						entry } ] ].
	request newestFirst ifTrue: [ ^ pairs reversed asOrderedCollection ].
	^ pairs
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> pageFrom: entryPairs offset: anOffset limit: aLimit [

	| start stop |
	aLimit = 0 ifTrue: [ ^ #(  ) ].
	anOffset >= entryPairs size ifTrue: [ ^ #(  ) ].
	start := anOffset + 1.
	stop := anOffset + aLimit min: entryPairs size.
	^ entryPairs copyFrom: start to: stop
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> referenceStringFor: aReference [

	aReference ifNil: [ ^ nil ].
	(aReference respondsTo: #shortName) ifTrue: [
		^ aReference shortName asString ].
	^ aReference asString
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPListChangeHistoryEntriesCommand >> tool [

	^ tool
]
