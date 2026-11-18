"
Shared implementation for change-history tools.

The public API talks about change history rather than Epicea or Ombu; the implementation uses Epicea logs and .ombu files behind the scenes. This class holds the steps every history tool takes to read one: the file the session in progress writes, the directory that holds it, and loading a log from that session or from a named .ombu file. A tool reads what it needs in dataFor:, describes it with MCPChangeHistoryLogInfo and MCPChangeHistoryEntryInfo, and says what it found in successSummaryForData:.
"
Class {
	#name : 'MCPToolChangeHistory',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolChangeHistory class >> groupName [

	^ self historyGroupName
]

{ #category : 'testing' }
MCPToolChangeHistory class >> isAbstract [

	^ self = MCPToolChangeHistory
]

{ #category : 'metadata' }
MCPToolChangeHistory >> additionalKeywords [

	^ #( 'history' 'change' 'epicea' 'ombu' 'recover' )
]

{ #category : 'private - history' }
MCPToolChangeHistory >> currentHistoryFileReference [
	"The file the session in progress writes its history to, nil without a change history monitor."

	EpMonitor hasCurrent ifFalse: [ ^ nil ].
	EpMonitor current sessionStore flush.
	^ EpMonitor current log store writingFileReference
]

{ #category : 'private - history' }
MCPToolChangeHistory >> currentLogAndFileName [

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

{ #category : 'private - execution' }
MCPToolChangeHistory >> dataFor: request [
	"The data the answer carries, read from the image as the request asks."

	^ self subclassResponsibility
]

{ #category : 'executing' }
MCPToolChangeHistory >> executeWithRequest: request [
	"Every history tool answers the data it reads, under a sentence that says what it found."

	^ self
		  executeRequest: request
		  do: [
				  | data |
				  data := self dataFor: request.
				  self successResultText: (self successSummaryForData: data) data: data ]
		  onError: [ :error | self errorResultFor: error ]
]

{ #category : 'private - history' }
MCPToolChangeHistory >> historyDirectoryForCurrentFile: aFileReference [

	aFileReference ifNotNil: [ ^ aFileReference parent ].
	^ [ EpMonitor logsDirectory ]
		  on: Error
		  do: [ :error | FileLocator localDirectory asFileReference ]
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> historyLocationInputProperties [
	"Which .ombu file the entries come from. One definition, shared by every change-history tool."

	^ {
		  (self
			   schemaPropertyNamed: 'directoryPath'
			   type: 'string'
			   description: 'Directory holding the .ombu files. Defaults to this image''s own history directory.').
		  (self
			   schemaPropertyNamed: 'historyFile'
			   type: 'string'
			   description: 'One .ombu file in that directory, named as history_file_list prints it. Defaults to the session in progress.') }
]

{ #category : 'private - schema' }
MCPToolChangeHistory >> integerArraySchemaNamed: aName description: aDescription itemDescription: anItemDescription [

	| itemsProperty |
	itemsProperty := MCPStructureProperties new
		                 type: 'integer';
		                 description: anItemDescription;
		                 yourself.
	^ (self schemaPropertyNamed: aName type: 'array' description: aDescription)
		  items: itemsProperty;
		  yourself
]

{ #category : 'private - results' }
MCPToolChangeHistory >> keyOrder [
	"index is the handle every history tool takes, so it leads, then what happened and when, then what a method was before the change and after it."

	^ #( index eventClass time sourceBefore sourceAfter )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> keysStatedInSummary [
	"The summary already says how many entries, and the offset the next page starts at."

	^ #( nextOffset )
]

{ #category : 'private - results' }
MCPToolChangeHistory >> listedSummaryForCount: anInteger noun: aNoun data: data [
	"A page of files or entries says how many it holds and, when another follows, the offset it starts at: the text leaves nextOffset to this sentence."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Listed ';
				  nextPutAll: (self textForCount: anInteger noun: aNoun);
				  nextPut: $..
			  data at: #nextOffset ifPresent: [ :offset |
					  stream
						  nextPutAll: ' Next page: offset ';
						  print: offset;
						  nextPut: $. ] ]
]

{ #category : 'private - history' }
MCPToolChangeHistory >> logAndFileNameFor: request [
	"The log the request names by directoryPath and historyFile, else the one of the session in progress, and the name of its file."

	^ self
		  logAndFileNameFromDirectoryPath: (request stringArgumentNamed: 'directoryPath')
		  fileName: (request stringArgumentNamed: 'historyFile')
]

{ #category : 'private - history' }
MCPToolChangeHistory >> logAndFileNameFromDirectoryPath: directoryPath fileName: fileName [

	| currentFile directory file |
	fileName ifNil: [
			directoryPath ifNotNil: [ self refuseDirectoryPathWithoutFile: directoryPath ].
			^ self currentLogAndFileName ].
	currentFile := self currentHistoryFileReference.
	directoryPath ifNotNil: [ self refuseRelativeDirectoryPath: directoryPath ].
	directory := directoryPath
		             ifNil: [ self historyDirectoryForCurrentFile: currentFile ]
		             ifNotNil: [ directoryPath asFileReference ].
	directory exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryDirectoryNotFound
				message:
				(String streamContents: [ :stream | stream << 'Change history directory ' << directory fullName << ' does not exist.' ])
				details: { (#directoryPath -> directory fullName) } asDictionary ].
	directory isDirectory ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotDirectory
				message:
				(String streamContents: [ :stream | stream << 'Change history path ' << directory fullName << ' is not a directory.' ])
				details: { (#directoryPath -> directory fullName) } asDictionary ].
	file := directory / fileName.
	^ self logAndFileNameFromFileReference: file
]

{ #category : 'private - history' }
MCPToolChangeHistory >> logAndFileNameFromFileReference: aFileReference [

	| log |
	aFileReference exists ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryFileNotFound
				message:
				(String streamContents: [ :stream | stream << 'Change history file ' << aFileReference fullName << ' does not exist.' ])
				details: {
						(#directoryPath -> aFileReference parent fullName).
						(#historyFile -> aFileReference basename) } asDictionary ].
	aFileReference isFile ifFalse: [
			MCPCommandError
				signalErrorCode: #ChangeHistoryPathNotFile
				message:
				(String streamContents: [ :stream | stream << 'Change history path ' << aFileReference fullName << ' is not a file.' ])
				details: {
						(#directoryPath -> aFileReference parent fullName).
						(#historyFile -> aFileReference basename) } asDictionary ].
	log := [
		       | loadedLog |
		       loadedLog := EpLog freshFromFile: aFileReference.
		       loadedLog entries size.
		       loadedLog ]
		       on: Error
		       do: [ :error |
				       MCPCommandError
					       signalErrorCode: #ChangeHistoryFileUnreadable
					       message:
					       (String streamContents: [ :stream |
						        stream << 'Change history file ' << aFileReference fullName << ' could not be loaded.' ])
					       details: {
							       (#directoryPath -> aFileReference parent fullName).
							       (#historyFile -> aFileReference basename).
							       (#causeClass -> error class name).
							       (#causeMessage -> (error messageText ifNil: [ error asString ])) } asDictionary ].
	^ {
		  log.
		  aFileReference basename }
]

{ #category : 'private - results' }
MCPToolChangeHistory >> redundantKeys [
	"An entry's summary prints its event class around its behavior and selector, which the entry already names."

	^ #( summary )
]

{ #category : 'private - history' }
MCPToolChangeHistory >> refuseDirectoryPathWithoutFile: directoryPath [
	"A directory alone names no file. The session in progress is the default only in the directory that holds it: anywhere else the caller meant one of that directory's files, and answering the session in progress would read another history than the one asked for."

	| currentFile |
	self refuseRelativeDirectoryPath: directoryPath.
	currentFile := self currentHistoryFileReference.
	(currentFile isNotNil and: [ currentFile parent fullName = directoryPath asFileReference fullName ]) ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #ChangeHistoryFileNotNamed
		message: (String streamContents: [ :stream |
					 stream << 'Change history directory ' << directoryPath
					 << ' does not hold the session in progress: name one of its files with historyFile, as history_file_list lists them.' ])
		details: { (#directoryPath -> directoryPath) } asDictionary
]

{ #category : 'private - history' }
MCPToolChangeHistory >> refuseRelativeDirectoryPath: directoryPath [
	"The image would resolve a relative directory against its own working directory, which is not the caller's."

	directoryPath asFileReference isAbsolute ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #ChangeHistoryDirectoryNotAbsolute
		message: (String streamContents: [ :stream |
					 stream << 'Change history directory ' << directoryPath
					 << ' is not an absolute path, and the image would resolve it against its own working directory, '
					 << FileSystem workingDirectory fullName << '. Give the full path.' ])
		details: { (#directoryPath -> directoryPath) } asDictionary
]

{ #category : 'private - history' }
MCPToolChangeHistory >> sameFileReference: firstFile as: secondFile [

	firstFile ifNil: [ ^ false ].
	secondFile ifNil: [ ^ false ].
	^ firstFile fullName = secondFile fullName
]

{ #category : 'private - results' }
MCPToolChangeHistory >> successSummaryForData: data [
	"The sentence that says what the data holds."

	^ self subclassResponsibility
]
