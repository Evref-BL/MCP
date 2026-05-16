"
Command that lists change history files available to the running image.
"
Class {
	#name : 'MCPListChangeHistoryLogsCommand',
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
MCPListChangeHistoryLogsCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> currentHistoryFileReference [

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
MCPListChangeHistoryLogsCommand >> directoryForRequestWithCurrentFile: currentFile [

	| directory |
	request directoryPath ifNil: [
		^ self historyDirectoryForCurrentFile: currentFile ].
	directory := request directoryPath asFileReference.
	directory exists ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryDirectoryNotFound
			message: 'Change history directory ' , request directoryPath
				, ' does not exist.'
			details: { (#directoryPath -> request directoryPath) } asDictionary ].
	directory isDirectory ifFalse: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryPathNotDirectory
			message: 'Change history path ' , request directoryPath
				, ' is not a directory.'
			details: { (#directoryPath -> request directoryPath) } asDictionary ].
	^ directory
]

{ #category : 'execution' }
MCPListChangeHistoryLogsCommand >> execute [

	| currentFile directory files logs includeFile |
	currentFile := self currentHistoryFileReference.
	directory := self directoryForRequestWithCurrentFile: currentFile.
	includeFile := request directoryPath
		               ifNil: [ currentFile ]
		               ifNotNil: [ nil ].
	files := self
		         historyFileReferencesFrom: directory
		         including: includeFile.
	logs := files collect: [ :each |
		        MCPChangeHistoryLogInfo
			        fromFileReference: each
			        isCurrent: (self sameFileReference: each as: currentFile)
			        includeEntryCounts: request includeEntryCounts ].
	^ MCPChangeHistoryListLogsResult
		  currentLogPath: (currentFile ifNotNil: [ currentFile fullName ])
		  directoryPath: (directory ifNotNil: [ directory fullName ])
		  logs: logs
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> historyDirectoryForCurrentFile: aFileReference [

	aFileReference ifNotNil: [ ^ aFileReference parent ].
	^ [ EpMonitor logsDirectory ]
		  on: Error
		  do: [ :error | FileLocator localDirectory asFileReference ]
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> historyFileReferencesFrom: aDirectory including: currentFile [

	| files |
	files := (aDirectory notNil and: [ aDirectory exists ])
		         ifTrue: [
		         aDirectory files select: [ :each | each extension = 'ombu' ] ]
		         ifFalse: [ #(  ) ].
	(currentFile notNil and: [
		 (files anySatisfy: [ :each |
			  self sameFileReference: each as: currentFile ]) not ]) ifTrue: [
		files := files copyWith: currentFile ].
	^ (files asSortedCollection: [ :left :right |
		   self shouldSortFile: left before: right ]) asArray
]

{ #category : 'initialization' }
MCPListChangeHistoryLogsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> modificationTimeOf: aFileReference [

	^ [ aFileReference modificationTime ]
		  on: Error
		  do: [ :error | nil ]
]

{ #category : 'accessing' }
MCPListChangeHistoryLogsCommand >> request [

	^ request
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> sameFileReference: firstFile as: secondFile [

	(firstFile isNil or: [ secondFile isNil ]) ifTrue: [ ^ false ].
	^ [ firstFile fullName = secondFile fullName ]
		  on: Error
		  do: [ :error | firstFile = secondFile ]
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> shouldSortFile: leftFile before: rightFile [

	| leftTime rightTime |
	leftTime := self modificationTimeOf: leftFile.
	rightTime := self modificationTimeOf: rightFile.
	(leftTime isNil and: [ rightTime isNil ]) ifTrue: [
		^ leftFile basename <= rightFile basename ].
	leftTime ifNil: [ ^ false ].
	rightTime ifNil: [ ^ true ].
	^ leftTime >= rightTime
]

{ #category : 'accessing' }
MCPListChangeHistoryLogsCommand >> tool [

	^ tool
]
