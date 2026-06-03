"
Abstract base for image change-history commands.

It centralizes command construction, current Epicea log access, history-file loading, and small reference predicates shared by change-history list and selection commands.
"
Class {
	#name : 'MCPChangeHistoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPChangeHistoryCommand class >> isAbstract [

	^ self = MCPChangeHistoryCommand
]

{ #category : 'instance creation' }
MCPChangeHistoryCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> currentHistoryFileReference [

	EpMonitor hasCurrent ifFalse: [ ^ nil ].
	EpMonitor current sessionStore flush.
	^ EpMonitor current log store writingFileReference
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> currentLogAndPath [

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

{ #category : 'initialization' }
MCPChangeHistoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'private - entries' }
MCPChangeHistoryCommand >> isCodeChangeEntry: anEntry [

	^ anEntry content isCodeChange
]

{ #category : 'private - log' }
MCPChangeHistoryCommand >> logAndPathFromFilePath: aPathString [

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

{ #category : 'private - references' }
MCPChangeHistoryCommand >> referenceStringFor: aReference [

	aReference isNull ifTrue: [ ^ nil ].
	^ aReference shortName asString
]

{ #category : 'accessing' }
MCPChangeHistoryCommand >> request [

	^ request
]

{ #category : 'private - files' }
MCPChangeHistoryCommand >> sameFileReference: firstFile as: secondFile [

	firstFile ifNil: [ ^ false ].
	secondFile ifNil: [ ^ false ].
	^ firstFile fullName = secondFile fullName
]

{ #category : 'accessing' }
MCPChangeHistoryCommand >> tool [

	^ tool
]
