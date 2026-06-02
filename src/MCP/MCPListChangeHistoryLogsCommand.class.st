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
MCPListChangeHistoryLogsCommand >> currentHistoryFileToInclude: currentFile inDirectory: aDirectory [

	currentFile ifNil: [ ^ nil ].
	request directoryPath ifNil: [ ^ currentFile ].
	(self sameFileReference: aDirectory as: currentFile parent) ifFalse: [
		^ nil ].
	^ currentFile
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> directoryForRequestWithCurrentFile: currentFile [

	| directory directoryPath |
	directoryPath := request directoryPath.
	directoryPath ifNil: [
		^ self historyDirectoryForCurrentFile: currentFile ].
	directory := directoryPath asFileReference.
	currentFile ifNotNil: [
			(self sameFileReference: directory as: currentFile) ifTrue: [
					MCPCommandError
						signalErrorCode: #ChangeHistoryPathNotDirectory
						message:
						'Change history path ' , directoryPath , ' is not a directory.'
						details: { (#directoryPath -> directoryPath) } asDictionary ] ].
	directory exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryDirectoryNotFound
				message:
				'Change history directory ' , directoryPath , ' does not exist.'
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	directory isDirectory ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotDirectory
				message:
				'Change history path ' , directoryPath , ' is not a directory.'
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	^ directory
]

{ #category : 'execution' }
MCPListChangeHistoryLogsCommand >> execute [

	| currentFile directory files logs includeFile |
	currentFile := self currentHistoryFileReference.
	directory := self directoryForRequestWithCurrentFile: currentFile.
	includeFile := self
		               currentHistoryFileToInclude: currentFile
		               inDirectory: directory.
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
	files := aDirectory ifNil: [ #(  ) ] ifNotNil: [ :directory |
			         directory exists
				         ifTrue: [
				         directory files select: [ :each |
					         each extension = 'ombu' ] ]
				         ifFalse: [ #(  ) ] ].
	currentFile ifNotNil: [
			(files anySatisfy: [ :each |
				 self sameFileReference: each as: currentFile ]) ifFalse: [
				files := files copyWith: currentFile ] ].
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
