"
Abstract base for image change-history commands.

It centralizes command construction, current Epicea log access, history-file loading, and small reference predicates shared by change-history list and selection commands.
"
Class {
	#name : 'MCPChangeHistoryCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPChangeHistoryCommand class >> isAbstract [

	^ self = MCPChangeHistoryCommand
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> currentHistoryFileReference [

	EpMonitor hasCurrent ifFalse: [ ^ nil ].
	EpMonitor current sessionStore flush.
	^ EpMonitor current log store writingFileReference
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> currentLogAndFileName [

	| currentFile log |
	EpMonitor hasCurrent ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryUnavailable
				message: 'No current Pharo change history monitor is available.'
				details: Dictionary new ].
	EpMonitor current sessionStore flush.
	log := EpMonitor current log.
	log refresh.
	currentFile := self currentHistoryFileReference.
	^ {
		  log.
		  (currentFile ifNotNil: [ currentFile basename ]) }
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> historyDirectoryForCurrentFile: aFileReference [

	aFileReference ifNotNil: [ ^ aFileReference parent ].
	^ [ EpMonitor logsDirectory ]
		  on: Error
		  do: [ :error | FileLocator localDirectory asFileReference ]
]

{ #category : 'private - entries' }
MCPChangeHistoryCommand >> isCodeChangeEntry: anEntry [

	^ anEntry content isCodeChange
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> logAndFileNameFromDirectoryPath: directoryPath fileName: fileName [

	| currentFile directory file |
	fileName ifNil: [ ^ self currentLogAndFileName ].
	currentFile := self currentHistoryFileReference.
	directory := directoryPath
		             ifNil: [
		             self historyDirectoryForCurrentFile: currentFile ]
		             ifNotNil: [ directoryPath asFileReference ].
	directory exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryDirectoryNotFound
				message:
				'Change history directory ' , directory fullName
				, ' does not exist.'
				details: { (#directoryPath -> directory fullName) } asDictionary ].
	directory isDirectory ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotDirectory
				message:
				'Change history path ' , directory fullName
				, ' is not a directory.'
				details: { (#directoryPath -> directory fullName) } asDictionary ].
	file := directory / fileName.
	^ self logAndFileNameFromFileReference: file
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> logAndFileNameFromFileReference: aFileReference [

	| log |
	aFileReference exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryFileNotFound
				message:
				'Change history file ' , aFileReference fullName
				, ' does not exist.'
				details: {
						(#directoryPath -> aFileReference parent fullName).
						(#historyFileName -> aFileReference basename) } asDictionary ].
	aFileReference isFile ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotFile
				message:
				'Change history path ' , aFileReference fullName
				, ' is not a file.'
				details: {
						(#directoryPath -> aFileReference parent fullName).
						(#historyFileName -> aFileReference basename) } asDictionary ].
	log := [
		       | loadedLog |
		       loadedLog := EpLog freshFromFile: aFileReference.
		       loadedLog entries size.
		       loadedLog ]
		       on: Error
		       do: [ :error |
				       MCPCommandError
					       signalErrorCode: #ChangeHistoryFileUnreadable
					       message: 'Change history file ' , aFileReference fullName
						       , ' could not be loaded.'
					       details: {
							       (#directoryPath -> aFileReference parent fullName).
							       (#historyFileName -> aFileReference basename).
							       (#causeClass -> error class name).
							       (#causeMessage
							        -> (error messageText ifNil: [ error asString ])) }
							       asDictionary ].
	^ {
		  log.
		  aFileReference basename }
]

{ #category : 'private - files' }
MCPChangeHistoryCommand >> sameFileReference: firstFile as: secondFile [

	firstFile ifNil: [ ^ false ].
	secondFile ifNil: [ ^ false ].
	^ firstFile fullName = secondFile fullName
]
