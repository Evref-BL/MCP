"
Lists the change history files of a directory, the one holding this image's history unless another is named, the most recently modified first.

execute answers the file references; isCurrentFile: then tells which one holds the session in progress.
"
Class {
	#name : 'MCPListChangeHistoryLogsCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#instVars : [
		'directoryPath',
		'currentFile'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPListChangeHistoryLogsCommand class >> directoryPath: aPathString [
	"aPathString names the directory to list, or is nil for the one holding this image's history."

	^ self new
		  directoryPath: aPathString;
		  yourself
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> currentHistoryFileToIncludeIn: aDirectory [

	currentFile ifNil: [ ^ nil ].
	directoryPath ifNil: [ ^ currentFile ].
	(self sameFileReference: aDirectory as: currentFile parent) ifFalse: [ ^ nil ].
	^ currentFile
]

{ #category : 'accessing' }
MCPListChangeHistoryLogsCommand >> directoryPath: aPathString [

	directoryPath := aPathString
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> directoryToList [

	| directory |
	directoryPath ifNil: [ ^ self historyDirectoryForCurrentFile: currentFile ].
	directory := directoryPath asFileReference.
	currentFile ifNotNil: [
			(self sameFileReference: directory as: currentFile) ifTrue: [
					MCPCommandError
						signalErrorCode: #ChangeHistoryPathNotDirectory
						message: (String streamContents: [ :stream | stream << 'Change history path ' << directoryPath << ' is not a directory.' ])
						details: { (#directoryPath -> directoryPath) } asDictionary ] ].
	directory exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryDirectoryNotFound
				message: (String streamContents: [ :stream | stream << 'Change history directory ' << directoryPath << ' does not exist.' ])
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	directory isDirectory ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotDirectory
				message: (String streamContents: [ :stream | stream << 'Change history path ' << directoryPath << ' is not a directory.' ])
				details: { (#directoryPath -> directoryPath) } asDictionary ].
	^ directory
]

{ #category : 'execution' }
MCPListChangeHistoryLogsCommand >> execute [
	"Answer the history files of the directory, the most recently modified first, with the session in progress among them when it is kept there."

	| directory |
	currentFile := self currentHistoryFileReference.
	directory := self directoryToList.
	^ self historyFileReferencesFrom: directory including: (self currentHistoryFileToIncludeIn: directory)
]

{ #category : 'private' }
MCPListChangeHistoryLogsCommand >> historyFileReferencesFrom: aDirectory including: aFile [

	| files |
	files := aDirectory ifNil: [ #(  ) ] ifNotNil: [ :directory |
			         directory exists
				         ifTrue: [ directory files select: [ :each | each extension = 'ombu' ] ]
				         ifFalse: [ #(  ) ] ].
	aFile ifNotNil: [
		(files anySatisfy: [ :each | self sameFileReference: each as: aFile ]) ifFalse: [ files := files copyWith: aFile ] ].
	^ files asArray sort: [ :left :right | self shouldSortFile: left before: right ]
]

{ #category : 'testing' }
MCPListChangeHistoryLogsCommand >> isCurrentFile: aFileReference [
	"Whether aFileReference holds the session in progress, as execute found it."

	^ self sameFileReference: aFileReference as: currentFile
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
	(leftTime isNil and: [ rightTime isNil ]) ifTrue: [ ^ leftFile basename <= rightFile basename ].
	leftTime ifNil: [ ^ false ].
	rightTime ifNil: [ ^ true ].
	^ leftTime >= rightTime
]
