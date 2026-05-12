"
Tests for the image change history management MCP tool.
"
Class {
	#name : 'MCPToolManageChangeHistoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolManageChangeHistoryTest class >> shouldLogWithEpicea [
	"These tests intentionally create recoverable code changes and then exercise the change-history apply/revert machinery."

	^ true
]

{ #category : 'private' }
MCPToolManageChangeHistoryTest >> isRecoverableMethodEntry: anEntry forClass: aClass [

	| event |
	event := anEntry content.
	((event respondsTo: #methodAffectedSelector) and: [
		 event methodAffectedSelector = #rescuedValue ]) ifFalse: [ ^ false ].
	((event respondsTo: #behaviorAffectedName) and: [
		 event behaviorAffectedName = aClass name ]) ifFalse: [ ^ false ].
	^ (event respondsTo: #isCodeChange) and: [ event isCodeChange ]
]

{ #category : 'private' }
MCPToolManageChangeHistoryTest >> latestRecoverableMethodEntryIndexFor: aClass [

	| foundIndex |
	EpMonitor current log refresh.
	EpMonitor current log entries doWithIndex: [ :entry :index |
		(self isRecoverableMethodEntry: entry forClass: aClass) ifTrue: [
			foundIndex := index ] ].
	foundIndex ifNil: [
		self fail: 'Expected recoverable method entry in change history.' ].
	^ foundIndex
]

{ #category : 'private' }
MCPToolManageChangeHistoryTest >> recordMethodAdditionOn: aClass [

	aClass compile: 'rescuedValue ^ 42' classified: 'testing'.
	EpMonitor current sessionStore flush.
	^ self latestRecoverableMethodEntryIndexFor: aClass
]

{ #category : 'private' }
MCPToolManageChangeHistoryTest >> recordRecoverableMethodAdditionOn: aClass [

	| index |
	index := self recordMethodAdditionOn: aClass.
	self removeSelector: #rescuedValue from: aClass.
	^ index
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesAppliesConfirmedChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		self deny: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#operation -> 'applyEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> true) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #operation) equals: 'applyEntries'.
		self assert: (data at: #action) equals: 'apply'.
		self assert: (data at: #performed).
		self assert: (data at: #performedCount) equals: 1.
		self assert: (class includesSelector: #rescuedValue).
		self
			assert: (class >> #rescuedValue) sourceCode
			equals: 'rescuedValue ^ 42' ]
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesPreviewsChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex previewEntry result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		result := self callToolWith: {
				          (#operation -> 'applyEntries').
				          (#indexes -> { entryIndex }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #operation) equals: 'applyEntries'.
		self assert: (data at: #action) equals: 'apply'.
		self assert: (data at: #selectedCount) equals: 1.
		self assert: (data at: #previewCount) equals: 1.
		self deny: (data at: #performed).
		previewEntry := (data at: #previewEntries) first.
		self assert: (previewEntry at: #selector) equals: 'rescuedValue' ]
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesRejectsIncompleteRange [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'applyEntries').
			          (#startIndex -> 1) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryInvalidSelection'.
	self assert: (error at: #startIndex) equals: 1.
	self assert: (error at: #endIndex) isNil
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesRejectsNonPositiveIndex [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'applyEntries').
			          (#indexes -> #( 0 )) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryInvalidSelection'.
	self assert: (error at: #argumentName) equals: 'indexes'.
	self assert: (error at: #actualValue) equals: 0
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesRequiresSelectionCriteria [

	| error result |
	result := self callToolWith:
		          { (#operation -> 'applyEntries') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryInvalidSelection'
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testApplyEntriesWithoutConfirmOnlyPreviews [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		self deny: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#operation -> 'applyEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> false) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #operation) equals: 'applyEntries'.
		self assert: (data at: #action) equals: 'apply'.
		self deny: (data at: #performed).
		self assert: (data at: #performedCount) equals: 0.
		self assert: (data at: #previewCount) equals: 1.
		self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListEntriesReportsDirectoryPathAsNotFile [

	| data directoryPath error result |
	data := self dataFrom: (self callToolWith: {
				         (#operation -> 'listFiles').
				         (#includeEntryCounts -> false) } asDictionary).
	directoryPath := data at: #directoryPath.
	result := self callToolWith: {
			          (#operation -> 'listEntries').
			          (#historyFilePath -> directoryPath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryPathNotFile'.
	self assert: (error at: #historyFilePath) equals: directoryPath
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListEntriesReportsUnreadableHistoryFile [

	| error file result |
	file := FileLocator temp asFileReference
	        /
	        ('mcp-unreadable-change-history-' , UUID new asString
	         , '.ombu').
	[
	file writeStreamDo: [ :stream |
		stream nextPutAll: 'not an ombu history file' ].
	result := self callToolWith: {
			          (#operation -> 'listEntries').
			          (#historyFilePath -> file fullName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryFileUnreadable'.
	self assert: (error at: #historyFilePath) equals: file fullName.
	self assert: (error includesKey: #causeClass) ] ensure: [
		file ensureDelete ]
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListEntriesReturnsGranularCodeChangeData [

	| data entries firstEntry result |
	result := self callToolWith: {
			          (#operation -> 'listEntries').
			          (#limit -> 5).
			          (#newestFirst -> true).
			          (#codeChangesOnly -> true) } asDictionary.
	data := self dataFrom: result.
	entries := data at: #entries.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #operation) equals: 'listEntries'.
	self assert: (data at: #limit) equals: 5.
	self assert: (data at: #codeChangesOnly).
	self assert: (data at: #totalCount) >= entries size.
	self assert: entries notEmpty.
	firstEntry := entries first.
	self assert: (firstEntry at: #isCodeChange).
	self assert: (firstEntry includesKey: #index).
	self assert: (firstEntry includesKey: #reference).
	self assert: (firstEntry includesKey: #eventClassName)
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListEntriesSupportsHistoryFilePath [

	| data entries files path result filesResult |
	filesResult := self callToolWith: {
			               (#operation -> 'listFiles').
			               (#includeEntryCounts -> false) } asDictionary.
	files := (self dataFrom: filesResult) at: #files.
	path := (files detect: [ :each | each at: #isCurrent ]) at: #path.
	result := self callToolWith: {
			          (#operation -> 'listEntries').
			          (#historyFilePath -> path).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	entries := data at: #entries.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #historyFilePath) equals: path.
	self assert: entries size <= 1.
	self assert: (data at: #totalCount) >= entries size
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListFilesReportsFilePathAsNotDirectory [

	| data error filePath result |
	data := self dataFrom: (self callToolWith: {
				         (#operation -> 'listFiles').
				         (#includeEntryCounts -> false) } asDictionary).
	filePath := data at: #currentLogPath.
	result := self callToolWith: {
			          (#operation -> 'listFiles').
			          (#directoryPath -> filePath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryPathNotDirectory'.
	self assert: (error at: #directoryPath) equals: filePath
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListFilesReportsMissingDirectoryPath [

	| error missingPath result |
	missingPath := (FileLocator temp asFileReference
	                / ('mcp-missing-change-history-' , UUID new asString))
		               fullName.
	result := self callToolWith: {
			          (#operation -> 'listFiles').
			          (#directoryPath -> missingPath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryDirectoryNotFound'.
	self assert: (error at: #directoryPath) equals: missingPath
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListFilesReturnsCurrentHistoryFile [

	| data files result |
	result := self callToolWith: {
			          (#operation -> 'listFiles').
			          (#includeEntryCounts -> false) } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #operation) equals: 'listFiles'.
	self assert: (data at: #currentLogPath) notNil.
	self assert: (data at: #directoryPath) notNil.
	self assert: files notEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ]).
	self assert: (files allSatisfy: [ :each |
			 (each includesKey: #path) and: [ each includesKey: #fileName ] ])
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testListFilesSupportsDirectoryPath [

	| baseData data directoryPath files result |
	baseData := self dataFrom: (self callToolWith: {
				             (#operation -> 'listFiles').
				             (#includeEntryCounts -> false) } asDictionary).
	directoryPath := baseData at: #directoryPath.
	result := self callToolWith: {
			          (#operation -> 'listFiles').
			          (#directoryPath -> directoryPath).
			          (#includeEntryCounts -> false) } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #operation) equals: 'listFiles'.
	self assert: (data at: #directoryPath) equals: directoryPath.
	self assert: files notEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ])
]

{ #category : 'tests' }
MCPToolManageChangeHistoryTest >> testRevertEntriesRevertsConfirmedChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordMethodAdditionOn: class.
		self assert: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#operation -> 'revertEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> true) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #operation) equals: 'revertEntries'.
		self assert: (data at: #action) equals: 'revert'.
		self assert: (data at: #performed).
		self assert: (data at: #performedCount) equals: 1.
		self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'private - calling' }
MCPToolManageChangeHistoryTest >> toolName [

	^ 'manage-change-history'
]

{ #category : 'private' }
MCPToolManageChangeHistoryTest >> withTemporaryRecoveryClassDo: aBlock [

	| className class |
	className := 'MCPToolManageChangeHistoryRecoveryTemp'.
	self removeClassNamed: className.
	[
	class := self
		         createClassNamed: className
		         superclassName: 'Object'
		         slots: #(  )
		         classSlots: #(  ).
	aBlock value: class ] ensure: [ self removeClassNamed: className ]
]
