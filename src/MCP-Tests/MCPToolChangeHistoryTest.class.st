"
Tests for the image change history management MCP tool.
"
Class {
	#name : 'MCPToolChangeHistoryTest',
	#superclass : 'MCPToolTestCase',
	#instVars : [
		'originalMonitor',
		'tempMonitor',
		'memoryDirectory',
		'originalMonitorWasEnabled'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPToolChangeHistoryTest class >> shouldLogWithEpicea [
	"These tests intentionally create recoverable code changes and then exercise the change-history apply/revert machinery."

	^ true
]

{ #category : 'private - calling' }
MCPToolChangeHistoryTest >> callToolWith: someArguments [

	| action arguments request result tool toolClass |
	arguments := someArguments copy.
	action := arguments removeKey: #action ifAbsent: [ nil ].
	toolClass := Dictionary new
		             at: 'listFiles' put: MCPToolListChangeHistoryFiles;
		             at: 'listEntries' put: MCPToolListChangeHistoryEntries;
		             at: 'applyEntries' put: MCPToolApplyChangeHistoryEntries;
		             at: 'revertEntries' put: MCPToolRevertChangeHistoryEntries;
		             at: action ifAbsent: [ Error signal: 'Unknown change history action: ' , action asString ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> defaultHistoryDirectoryPath [

	^ EpMonitor current log store writingFileReference parent fullName
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> entriesListedFor: someAssociations [
	"The entries history_entry_list lists for the arguments someAssociations name."

	^ (self dataFrom: (self callToolWith: (someAssociations copyWith: #action -> 'listEntries') asDictionary)) at: #entries
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> isRecoverableMethodEntry: anEntry forClass: aClass [

	^ (MCPChangeHistoryEntryInfo fromEvent: anEntry content) isMethodChangeForSelector: #rescuedValue inBehaviorNamed: aClass name
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> latestRecoverableMethodEntryIndexFor: aClass [

	| foundIndex |
	EpMonitor current log refresh.
	EpMonitor current log entries doWithIndex: [ :entry :index |
		(self isRecoverableMethodEntry: entry forClass: aClass) ifTrue: [ foundIndex := index ] ].
	foundIndex ifNil: [ self fail: 'Expected recoverable method entry in change history.' ].
	^ foundIndex
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> recordMethodAdditionOn: aClass [

	aClass compile: 'rescuedValue ^ 42' classified: 'testing'.
	EpMonitor current sessionStore flush.
	^ self latestRecoverableMethodEntryIndexFor: aClass
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> recordNonCodeEntry [
	"Record a session start, an entry that is no code change, and answer its index."

	EpMonitor current addEvent: EpSessionStart new.
	EpMonitor current sessionStore flush.
	EpMonitor current log refresh.
	^ EpMonitor current log entries size
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> recordRecoverableMethodAdditionOn: aClass [

	| index |
	index := self recordMethodAdditionOn: aClass.
	self removeSelector: #rescuedValue from: aClass.
	^ index
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> recordRescuedValue: aSource on: aClass [
	"Compile aSource as aClass's rescuedValue, and answer the index of the entry that records it."

	aClass compile: aSource classified: 'testing'.
	EpMonitor current sessionStore flush.
	^ self latestRecoverableMethodEntryIndexFor: aClass
]

{ #category : 'running' }
MCPToolChangeHistoryTest >> setUp [

	super setUp.
	originalMonitor := EpMonitor current.
	originalMonitorWasEnabled := originalMonitor isEnabled.
	originalMonitor disable.
	memoryDirectory := (FileSystem memory / ('mcp-history-test-' , UUID new asString36)) ensureCreateDirectory.
	tempMonitor := EpMonitor newWithLog: (EpLog newWithStore: (OmBlockFileStore named: 'log' inDirectory: memoryDirectory)).
	EpMonitor current: tempMonitor.
	tempMonitor enable
]

{ #category : 'running' }
MCPToolChangeHistoryTest >> tearDown [

	tempMonitor ifNotNil: [ tempMonitor disable ].
	originalMonitor ifNotNil: [
			EpMonitor current: originalMonitor.
			originalMonitorWasEnabled
				ifTrue: [ originalMonitor enable ]
				ifFalse: [ originalMonitor disable ] ].
	memoryDirectory ifNotNil: [ memoryDirectory ensureDeleteAll ].
	super tearDown
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testACompileKeepingTheSourceIsLoggedOnce [
	"A method compiled with format false is logged once, as compiled: no reformat follows it."

	self withTemporaryRecoveryClassDo: [ :class |
			self callToolNamed: 'method_compile' withArguments: {
					(#class -> class name).
					(#protocol -> 'testing').
					(#format -> false).
					(#source -> 'rescuedValue ^ 42') } asDictionary.
			EpMonitor current sessionStore flush.
			EpMonitor current log refresh.
			self assert: (EpMonitor current log entries count: [ :each | self isRecoverableMethodEntry: each forClass: class ]) equals: 1 ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testADirectoryWithoutAFileIsRefusedWhereTheSessionIsNot [
	"Answering the session in progress would read another history than the directory asked for."

	| directory error result |
	directory := FileLocator temp asFileReference / ('mcp-colleague-history-' , UUID new asString).
	[
		directory ensureCreateDirectory.
		result := self callToolWith: {
				          (#action -> 'listEntries').
				          (#directoryPath -> directory fullName) } asDictionary.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'ChangeHistoryFileNotNamed'.
		self assert: (error at: #message) equals: (String streamContents: [ :stream |
					 stream << 'Change history directory ' << directory fullName
					 << ' does not hold the session in progress: name one of its files with historyFile, as history_file_list lists them.' ]) ]
		ensure: [ directory ensureDeleteAll ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testADirectoryWithoutAFileListsTheSessionWhereItIs [

	| result |
	self useDiskBackedTemporaryLog.
	result := self callToolWith: {
			          (#action -> 'listEntries').
			          (#directoryPath -> self defaultHistoryDirectoryPath) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) includesKey: #entries)
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testANonCodeEntryChangesNothing [
	"An entry that is no code change is selected like any other, has nothing to apply, and says so."

	| entry |
	entry := ((self dataFrom: (self callToolWith: {
				            (#action -> 'applyEntries').
				            (#indexes -> { self recordNonCodeEntry }) } asDictionary)) at: #selectedEntries) first.
	self assert: (entry at: #eventClass) equals: 'EpSessionStart'.
	self assert: (entry at: #changesNothing) equals: 'not a code change'
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testARelativeDirectoryIsRefusedNamingTheImageDirectory [
	"The image would read history against its own working directory, which is not the caller's."

	{
		{ (#action -> 'listFiles') }.
		{
			(#action -> 'listEntries').
			(#historyFile -> 'colleague.ombu') } } do: [ :arguments |
			| error result |
			result := self callToolWith: (arguments , { (#directoryPath -> 'history') }) asDictionary.
			error := self errorFrom: result.
			self assert: (result at: #isError).
			self assert: (error at: #errorCode) equals: 'ChangeHistoryDirectoryNotAbsolute'.
			self assert: (error at: #message) equals: (String streamContents: [ :stream |
						 stream
						 <<
						 'Change history directory history is not an absolute path, and the image would resolve it against its own working directory, '
						 << FileSystem workingDirectory fullName << '. Give the full path.' ]) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyAndRevertPrintWhatTheySelected [
	"Each prints the entries it selected beside the changes it made, so an entry that changed nothing can be told; the selection criteria are the request read back."

	self withTemporaryRecoveryClassDo: [ :class |
			| textFor |
			textFor := [ :action :entryIndex |
				           self textFrom: (self callToolWith: {
							            (#action -> action).
							            (#indexes -> { entryIndex }) } asDictionary) ].
			{
				(textFor value: 'revertEntries' value: (self recordMethodAdditionOn: class)).
				(textFor value: 'applyEntries' value: (self recordRecoverableMethodAdditionOn: class)) } do: [ :text |
					self deny: (text includesSubstring: 'selectionCriteria').
					self assert: (text includesSubstring: 'selectedEntries:').
					self assert: (text includesSubstring: 'changes:') ] ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesAppliesChanges [
	"A call applies what it selects: there is no preview to confirm first."

	self withTemporaryRecoveryClassDo: [ :class |
			| data entryIndex result |
			entryIndex := self recordRecoverableMethodAdditionOn: class.
			self deny: (class includesSelector: #rescuedValue).
			result := self callToolWith: {
					          (#action -> 'applyEntries').
					          (#indexes -> { entryIndex }) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #action) equals: 'apply'.
			self assert: (data at: #selectedCount) equals: 1.
			self assert: (data at: #changeCount) equals: 1.
			self assert: ((data at: #changes) first at: #selector) equals: 'rescuedValue'.
			self assert: (self summaryFrom: result) equals: 'Applied 1 change from 1 selected history entry.'.
			self assert: (class >> #rescuedValue) sourceCode equals: 'rescuedValue ^ 42' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesRejectsNonPositiveIndex [

	| error result |
	result := self callToolWith: {
			          (#action -> 'applyEntries').
			          (#indexes -> #( 0 )) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ChangeHistoryInvalidSelection'.
	self assert: (error at: #argumentName) equals: 'indexes'.
	self assert: (error at: #actualValue) equals: 0
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesRequiresAnIndex [
	"indexes is the only way to name an entry, so a call without one, or with an empty list, names nothing to apply."

	| error result |
	self should: [ self callToolWith: { (#action -> 'applyEntries') } asDictionary ] raise: MCPInvalidToolInput.
	result := self callToolWith: {
			          (#action -> 'applyEntries').
			          (#indexes -> #(  )) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ChangeHistoryInvalidSelection'
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplySaysWhichSelectedEntriesChangeNothing [
	"Applying two changes to one method comes down to the later, and the image already holds it: each selected entry says why it changes nothing."

	self withTemporaryRecoveryClassDo: [ :class |
			| additionIndex data modificationIndex reasons |
			additionIndex := self recordRescuedValue: 'rescuedValue ^ 42' on: class.
			modificationIndex := self recordRescuedValue: 'rescuedValue ^ 43' on: class.
			data := self dataFrom: (self callToolWith: {
						         (#action -> 'applyEntries').
						         (#indexes -> {
							          additionIndex.
							          modificationIndex }) } asDictionary).
			reasons := (data at: #selectedEntries) collect: [ :each | (each at: #index) -> (each at: #changesNothing) ] as: Dictionary.
			self assert: (data at: #changes) isEmpty.
			self
				assert: (reasons at: additionIndex)
				equals: (String streamContents: [ :stream | stream << 'overridden by entry ' << modificationIndex printString ]).
			self assert: (reasons at: modificationIndex) equals: 'already applied in the image' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyingAnOlderVersionShowsTheSourceBeforeAndAfter [
	"Applying a method's addition once the method has changed puts the source it added back: the change is a modification from the source in the image to that one, under the addition's own index."

	self withTemporaryRecoveryClassDo: [ :class |
			| additionIndex change |
			additionIndex := self recordRescuedValue: 'rescuedValue ^ 42' on: class.
			self recordRescuedValue: 'rescuedValue ^ 43' on: class.
			change := ((self dataFrom: (self callToolWith: {
						             (#action -> 'applyEntries').
						             (#indexes -> { additionIndex }) } asDictionary)) at: #changes) first.
			self assert: (change at: #index) equals: additionIndex.
			self assert: (change at: #eventClass) equals: 'EpMethodModification'.
			self assert: (change at: #sourceBefore) equals: 'rescuedValue ^ 43'.
			self assert: (change at: #sourceAfter) equals: 'rescuedValue ^ 42'.
			self assert: (class >> #rescuedValue) sourceCode equals: 'rescuedValue ^ 42' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testClassSideEntryReadsAsAClassSideMethod [
	"Epicea names the behavior of a class-side change with its class suffix. The entry carries the side apart, so it names the class alone, and reads the way Pharo writes a class-side method."

	self withTemporaryRecoveryClassDo: [ :class |
			| entry result text |
			class classSide compile: 'rescuedValue ^ 42' classified: 'testing'.
			EpMonitor current sessionStore flush.
			result := self callToolWith: {
					          (#action -> 'listEntries').
					          (#newestFirst -> true).
					          (#codeChangesOnly -> true) } asDictionary.
			entry := ((self dataFrom: result) at: #entries) first.
			self assert: (entry at: #behavior) equals: class name asString.
			self assert: (entry at: #side) equals: 'class'.
			text := (result at: #content) first at: #text.
			self assert: (text includesSubstring: ('{1} class>>rescuedValue' format: { class name })).
			self deny: (text includesSubstring: ' class class>>') ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesFromAnOffset [
	"offset pages the list as it is filtered: the entries listed from an offset are those the whole list holds past it."

	self withTemporaryRecoveryClassDo: [ :class |
			| entries |
			self recordRescuedValue: 'rescuedValue ^ 42' on: class.
			self recordRescuedValue: 'rescuedValue ^ 43' on: class.
			entries := self entriesListedFor: { (#class -> class name asString) }.
			self assert: entries size >= 2.
			self
				assert: (self entriesListedFor: {
							 (#class -> class name asString).
							 (#offset -> 1) })
				equals: entries allButFirst ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesOfOneClass [
	"class lists every change to the class, on both sides: its definition, its comment and its methods. Another class's changes are left out, and Foo class names the same class as Foo."

	self withTemporaryRecoveryClassDo: [ :class |
			| entries otherClassName |
			otherClassName := 'MCPToolChangeHistoryOtherTemp'.
			[
				(self
					 createClassNamed: otherClassName
					 superclassName: 'Object'
					 slots: #(  )
					 classSlots: #(  )) compile: 'rescuedValue ^ 1' classified: 'testing'.
				self recordRescuedValue: 'rescuedValue ^ 42' on: class.
				class classSide compile: 'rescuedValue ^ 7' classified: 'testing'.
				class comment: 'Recovered.'.
				class addInstVarNamed: 'rescuedState'.
				EpMonitor current sessionStore flush.
				entries := self entriesListedFor: { (#class -> class name asString) }.
				self assert: (entries allSatisfy: [ :each | (each at: #behavior) = class name asString ]).
				self assert:
					((entries collect: [ :each | (each at: #eventClass) -> (each at: #side ifAbsent: [ 'instance' ]) ] as: Set) includesAll: {
							 ('EpMethodAddition' -> 'instance').
							 ('EpMethodAddition' -> 'class').
							 ('EpBehaviorCommentChange' -> 'instance').
							 ('EpClassModification' -> 'instance') }).
				self assert: (self entriesListedFor: { (#class -> (class name asString , ' class')) }) equals: entries ] ensure: [
				self removeClassNamed: otherClassName ] ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesReportsDirectoryPathAsNotFile [

	| directory error result |
	self useDiskBackedTemporaryLog.
	directory := self defaultHistoryDirectoryPath asFileReference.
	result := self callToolWith: {
			          (#action -> 'listEntries').
			          (#directoryPath -> directory parent fullName).
			          (#historyFile -> directory basename) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ChangeHistoryPathNotFile'.
	self assert: (error at: #historyFile) equals: directory basename
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesReportsUnreadableHistoryFile [

	| error file result |
	file := FileLocator temp asFileReference
	        / (String streamContents: [ :stream | stream << 'mcp-unreadable-change-history-' << UUID new asString << '.ombu' ]).
	[
		file writeStreamDo: [ :stream | stream nextPutAll: 'not an ombu history file' ].
		result := self callToolWith: {
				          (#action -> 'listEntries').
				          (#directoryPath -> file parent fullName).
				          (#historyFile -> file basename) } asDictionary.
		error := self errorFrom: result.
		self assert: (result at: #isError).
		self assert: (error at: #errorCode) equals: 'ChangeHistoryFileUnreadable'.
		self assert: (error at: #historyFile) equals: file basename.
		self assert: (error includesKey: #causeClass) ] ensure: [ file ensureDelete ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesReturnsGranularCodeChangeData [

	self withTemporaryRecoveryClassDo: [ :class |
			| data entries firstEntry result |
			self recordMethodAdditionOn: class.
			result := self callToolWith: {
					          (#action -> 'listEntries').
					          (#newestFirst -> true).
					          (#codeChangesOnly -> true) } asDictionary.
			data := self dataFrom: result.
			entries := data at: #entries.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: entries isNotEmpty.
			firstEntry := entries first.
			self assert: (firstEntry includesKey: #index).
			self assert: (firstEntry includesKey: #eventClass).
			self deny: (firstEntry includesKey: #entryKind).
			self assert: (firstEntry at: #package) equals: self generatedPackageName.
			self assert: (firstEntry at: #behavior) equals: class name.
			self deny: (firstEntry includesKey: #side).
			self assert: (firstEntry at: #selector) equals: 'rescuedValue' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesSupportsHistoryFileName [

	| data entries file files filesResult result |
	self withTemporaryRecoveryClassDo: [ :class |
			self recordMethodAdditionOn: class.
			filesResult := self callToolWith: { (#action -> 'listFiles') } asDictionary.
			data := self dataFrom: filesResult.
			files := data at: #files.
			file := files
				        detect: [ :each | (each at: #isCurrent ifAbsent: [ false ]) and: [ each at: #exists ifAbsent: [ true ] ] ]
				        ifNone: [
				        files
					        detect: [ :each | each at: #exists ifAbsent: [ true ] ]
					        ifNone: [ self skip: 'No existing change history file.' ] ].
			result := self callToolWith: {
					          (#action -> 'listEntries').
					          (#historyFile -> (file at: #file)) } asDictionary.
			data := self dataFrom: result.
			entries := data at: #entries.
			self assert: (data at: #historyFile) equals: (file at: #file).
			self assert: entries size <= MCPToolListChangeHistoryEntries new defaultPageLimit ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReportsFilePathAsNotDirectory [

	| data error file filePath result |
	data := self dataFrom: (self callToolWith: { (#action -> 'listFiles') } asDictionary).
	file := (data at: #files) detect: [ :each | each at: #isCurrent ifAbsent: [ false ] ].
	filePath := (self defaultHistoryDirectoryPath asFileReference / (file at: #file)) fullName.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> filePath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ChangeHistoryPathNotDirectory'.
	self assert: (error at: #directoryPath) equals: filePath
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReportsMissingDirectoryPath [

	| error missingPath result |
	missingPath := (FileLocator temp asFileReference / ('mcp-missing-change-history-' , UUID new asString)) fullName.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> missingPath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ChangeHistoryDirectoryNotFound'.
	self assert: (error at: #directoryPath) equals: missingPath
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReturnsCurrentHistoryFile [

	| allowedFileKeys data files result |
	result := self callToolWith: { (#action -> 'listFiles') } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	allowedFileKeys := #( file exists fileSize modificationTime isCurrent ) asSet.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: files isNotEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ifAbsent: [ false ] ]).
	self assert: (files allSatisfy: [ :each |
			 (each includesKey: #file) and: [ each keys allSatisfy: [ :key | allowedFileKeys includes: key ] ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesSupportsDirectoryPath [

	| data directoryPath files result |
	self useDiskBackedTemporaryLog.
	directoryPath := self defaultHistoryDirectoryPath.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> directoryPath) } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (data includesKey: #action).
	self assert: files isNotEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ifAbsent: [ false ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testNonCodeEntryDictionaryHasExpectedShape [

	| entry |
	entry := (MCPChangeHistoryEntryInfo fromEvent: EpSessionStart new) asDictionary.
	self assert: entry equals: {
			(#eventClass -> 'EpSessionStart').
			(#entryKind -> 'session') } asDictionary
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testRevertEntriesRevertsChanges [
	"A call reverts what it selects, and says so."

	self withTemporaryRecoveryClassDo: [ :class |
			| data entryIndex result |
			entryIndex := self recordMethodAdditionOn: class.
			self assert: (class includesSelector: #rescuedValue).
			result := self callToolWith: {
					          (#action -> 'revertEntries').
					          (#indexes -> { entryIndex }) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #action) equals: 'revert'.
			self assert: (data at: #changeCount) equals: 1.
			self assert: (self summaryFrom: result) equals: 'Reverted 1 change from 1 selected history entry.'.
			self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testRevertUndoesTheOldestOfTheChangesToOneMethod [
	"A revert undoes the newest entry first, so reverting a method's addition and a later change to it comes down to removing the method: the change is the addition's, and the later change is overridden by it."

	self withTemporaryRecoveryClassDo: [ :class |
			| additionIndex change data modificationIndex selectedEntries |
			additionIndex := self recordRescuedValue: 'rescuedValue ^ 42' on: class.
			modificationIndex := self recordRescuedValue: 'rescuedValue ^ 43' on: class.
			data := self dataFrom: (self callToolWith: {
						         (#action -> 'revertEntries').
						         (#indexes -> {
							          additionIndex.
							          modificationIndex }) } asDictionary).
			change := (data at: #changes) first.
			selectedEntries := (data at: #selectedEntries) collect: [ :each | (each at: #index) -> each ] as: Dictionary.
			self assert: (data at: #changes) size equals: 1.
			self assert: (change at: #index) equals: additionIndex.
			self assert: (change at: #eventClass) equals: 'EpMethodRemoval'.
			self assert: (change at: #sourceBefore) equals: 'rescuedValue ^ 43'.
			self deny: ((selectedEntries at: additionIndex) includesKey: #changesNothing).
			self
				assert: ((selectedEntries at: modificationIndex) at: #changesNothing)
				equals: (String streamContents: [ :stream | stream << 'overridden by entry ' << additionIndex printString ]).
			self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testRevertingARemovalShowsTheSourceItRestores [
	"Reverting a removal adds the method back: the answer says so under the removal's own index, with the source it restored."

	self withTemporaryRecoveryClassDo: [ :class |
			| change removalIndex result source |
			source := String streamContents: [ :stream |
					          stream
						          nextPutAll: 'rescuedValue';
						          lf;
						          tab;
						          nextPutAll: '^ 42' ].
			self recordRescuedValue: source on: class.
			class removeSelector: #rescuedValue.
			EpMonitor current sessionStore flush.
			removalIndex := self latestRecoverableMethodEntryIndexFor: class.
			result := self callToolWith: {
					          (#action -> 'revertEntries').
					          (#indexes -> { removalIndex }) } asDictionary.
			change := ((self dataFrom: result) at: #changes) first.
			self assert: (change at: #index) equals: removalIndex.
			self assert: (change at: #eventClass) equals: 'EpMethodAddition'.
			self assert: (change at: #sourceAfter) equals: source.
			self deny: (change includesKey: #sourceBefore).
			self assert: ((self textFrom: result) includesSubstring: (String streamContents: [ :stream |
							  stream
								  nextPutAll: 'sourceAfter:';
								  lf;
								  nextPutAll: source ])).
			self assert: (class >> #rescuedValue) sourceCode equals: source ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testSelectionResultDataHasExpectedShape [

	| data entry index |
	index := self recordNonCodeEntry.
	data := (self dataFrom: (self callToolWith: {
				          (#action -> 'applyEntries').
				          (#indexes -> { index }) } asDictionary)) copy.
	entry := (data removeKey: #selectedEntries) first.
	self assert: data equals: {
			(#action -> 'apply').
			(#historyFile -> 'log.ombu').
			(#selectionCriteria -> { (#indexes -> { index }) } asDictionary).
			(#changes -> #(  )).
			(#selectedCount -> 1).
			(#selectedCodeChangeCount -> 0).
			(#changeCount -> 0) } asDictionary.
	self assert: (entry at: #index) equals: index.
	self assert: (entry at: #changesNothing) equals: 'not a code change'
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testSelectionToolsRouteToChangeHistorySelectionCommand [

	{
		(MCPToolApplyChangeHistoryEntries -> 'apply').
		(MCPToolRevertChangeHistoryEntries -> 'revert') } do: [ :association |
			| request tool |
			tool := association key new.
			request := tool requestFromToolCallArguments: { (#indexes -> { self recordNonCodeEntry }) } asDictionary.
			self assert: (tool selectionFor: request in: EpMonitor current log) class equals: MCPChangeHistorySelectionCommand.
			self assert: ((self dataFrom: (tool executeWithRequest: request) asJRPCJSON) at: #action) equals: association value ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testTraitClassSideEntryReadsAsAClassSideMethod [
	"Epicea names a trait's class side with classTrait. The entry names the trait alone and carries the side apart, as for a class, and class finds it under the trait's name."

	| entry trait |
	trait := self classNamed: 'TMCPToolMethodSearchFixture'.
	entry := MCPChangeHistoryEntryInfo fromEvent: (EpMethodAddition method: trait classTrait >> #mcpTraitFixtureValue).
	self assert: (entry asDictionary at: #behavior) equals: trait name asString.
	self assert: (entry asDictionary at: #side) equals: 'class'.
	self assert: (entry changesClassNamed: trait name asString)
]

{ #category : 'private - calling' }
MCPToolChangeHistoryTest >> toolName [

	self shouldNotImplement
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> useDiskBackedTemporaryLog [
	"directoryPath is a plain string in the tool's request schema, and the tool resolves it back to a FileReference via #asFileReference, which always resolves against the disk filesystem. Tests that pass an explicit directoryPath therefore need a real (still isolated, still cleaned up) disk directory rather than the FileSystem memory-backed log used elsewhere in this class."

	tempMonitor disable.
	memoryDirectory ensureDeleteAll.
	memoryDirectory := FileReference newTempFilePrefix: 'mcp-history-test-' suffix: ''.
	memoryDirectory ensureCreateDirectory.
	tempMonitor := EpMonitor newWithLog: (EpLog newWithStore: (OmBlockFileStore named: 'log' inDirectory: memoryDirectory)).
	EpMonitor current: tempMonitor.
	tempMonitor enable
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> withTemporaryRecoveryClassDo: aBlock [

	| className class |
	className := 'MCPToolChangeHistoryRecoveryTemp'.
	self removeClassNamed: className.
	[
		class := self
			         createClassNamed: className
			         superclassName: 'Object'
			         slots: #(  )
			         classSlots: #(  ).
		aBlock value: class ] ensure: [ self removeClassNamed: className ]
]
