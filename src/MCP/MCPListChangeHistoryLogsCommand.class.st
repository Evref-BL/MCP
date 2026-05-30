"
Command that lists change history files available to the running image.
"
Class {
	#name : 'MCPListChangeHistoryLogsCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> directoryForRequestWithCurrentFile: currentFile [

	| directory |
	request directoryPath ifNil: [
		^ self historyDirectoryForCurrentFile: currentFile ].
	directory := request directoryPath asFileReference.
	(currentFile notNil and: [
		 self sameFileReference: directory as: currentFile ]) ifTrue: [
		MCPCommandError
			signalErrorCode: #ChangeHistoryPathNotDirectory
			message: 'Change history path ' , request directoryPath
				, ' is not a directory.'
			details: { (#directoryPath -> request directoryPath) } asDictionary ].
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
	includeFile := (currentFile notNil and: [
		                request directoryPath isNil or: [
			                self
				                sameFileReference: directory
				                as: currentFile parent ] ])
		               ifTrue: [ currentFile ]
		               ifFalse: [ nil ].
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

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> modificationTimeOf: aFileReference [

	^ [ aFileReference modificationTime ]
		  on: Error
		  do: [ :error | nil ]
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
