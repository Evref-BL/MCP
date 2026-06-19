"
Tests for the image change history management MCP tool.
"
Class {
	#name : 'MCPToolChangeHistoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
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
		             at: action
		             ifAbsent: [ Error signal: 'Unknown change history action: ' , action asString ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON

]

{ #category : 'private' }
MCPToolChangeHistoryTest >> isRecoverableMethodEntry: anEntry forClass: aClass [

	^ (MCPChangeHistoryEntryInfo fromEvent: anEntry content)
		  isMethodChangeForSelector: #rescuedValue
		  inBehaviorNamed: aClass name
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> latestRecoverableMethodEntryIndexFor: aClass [

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
MCPToolChangeHistoryTest >> recordMethodAdditionOn: aClass [

	^ PharoCompatibility withNonInteractiveAuthorNamed: 'MCP' during: [
		  aClass compile: 'rescuedValue ^ 42' classified: 'testing'.
		  EpMonitor current sessionStore flush.
		  self latestRecoverableMethodEntryIndexFor: aClass ]
]

{ #category : 'private' }
MCPToolChangeHistoryTest >> recordRecoverableMethodAdditionOn: aClass [

	| index |
	index := self recordMethodAdditionOn: aClass.
	self removeSelector: #rescuedValue from: aClass.
	^ index
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesAppliesConfirmedChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		self deny: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#action -> 'applyEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> true) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #action) equals: 'apply'.
		self assert: (data at: #performed).
		self assert: (data at: #performedCount) equals: 1.
		self assert: (class includesSelector: #rescuedValue).
		self
			assert: (class >> #rescuedValue) sourceCode
			equals: 'rescuedValue ^ 42' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesPreviewsChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex previewEntry result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		result := self callToolWith: {
				          (#action -> 'applyEntries').
				          (#indexes -> { entryIndex }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #action) equals: 'apply'.
		self assert: (data at: #selectedCount) equals: 1.
		self assert: (data at: #previewCount) equals: 1.
		self deny: (data at: #performed).
		previewEntry := (data at: #previewEntries) first.
		self assert: (previewEntry at: #selector) equals: 'rescuedValue' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesRejectsIncompleteRange [

	| error result |
	result := self callToolWith: {
			          (#action -> 'applyEntries').
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
MCPToolChangeHistoryTest >> testApplyEntriesRejectsNonPositiveIndex [

	| error result |
	result := self callToolWith: {
			          (#action -> 'applyEntries').
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
MCPToolChangeHistoryTest >> testApplyEntriesRequiresSelectionCriteria [

	| error result |
	result := self callToolWith:
		          { (#action -> 'applyEntries') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryInvalidSelection'
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testApplyEntriesWithoutConfirmOnlyPreviews [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordRecoverableMethodAdditionOn: class.
		self deny: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#action -> 'applyEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> false) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #action) equals: 'apply'.
		self deny: (data at: #performed).
		self assert: (data at: #performedCount) equals: 0.
		self assert: (data at: #previewCount) equals: 1.
		self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesReportsDirectoryPathAsNotFile [

	| data directoryPath error result |
	data := self dataFrom: (self callToolWith: {
				         (#action -> 'listFiles').
				         (#includeEntryCounts -> false) } asDictionary).
	directoryPath := data at: #directoryPath.
	result := self callToolWith: {
			          (#action -> 'listEntries').
			          (#historyFilePath -> directoryPath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryPathNotFile'.
	self assert: (error at: #historyFilePath) equals: directoryPath
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesReportsUnreadableHistoryFile [

	| error file result |
	file := FileLocator temp asFileReference
	        /
	        ('mcp-unreadable-change-history-' , UUID new asString
	         , '.ombu').
	[
	file writeStreamDo: [ :stream |
		stream nextPutAll: 'not an ombu history file' ].
	result := self callToolWith: {
			          (#action -> 'listEntries').
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
MCPToolChangeHistoryTest >> testListEntriesReturnsGranularCodeChangeData [

	self withTemporaryRecoveryClassDo: [ :class |
			| data entries firstEntry result |
			self recordMethodAdditionOn: class.
			result := self callToolWith: {
					          (#action -> 'listEntries').
					          (#limit -> 5).
					          (#newestFirst -> true).
					          (#codeChangesOnly -> true) } asDictionary.
			data := self dataFrom: result.
			entries := data at: #entries.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: entries notEmpty.
			firstEntry := entries first.
			self assert: (firstEntry at: #isCodeChange).
			self assert: (firstEntry includesKey: #index).
			self assert: (firstEntry includesKey: #reference).
			self assert: (firstEntry includesKey: #eventClassName).
			self assert: (firstEntry at: #packageName) equals: 'MCP-Tests'.
			self assert: (firstEntry at: #behaviorName) equals: class name.
			self assert: (firstEntry at: #classSide) equals: false.
			self assert: (firstEntry at: #selector) equals: 'rescuedValue' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListEntriesSupportsHistoryFilePath [

	| data entries files filesResult path result |
	filesResult := self callToolWith: {
			               (#action -> 'listFiles').
			               (#includeEntryCounts -> false) } asDictionary.
	files := (self dataFrom: filesResult) at: #files.
	path := (files detect: [ :each | each at: #isCurrent ]) at: #path.
	result := self callToolWith: {
			          (#action -> 'listEntries').
			          (#historyFilePath -> path).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	entries := data at: #entries.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #historyFilePath) equals: path.
	self assert: entries size <= 1
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReportsFilePathAsNotDirectory [

	| data error filePath result |
	data := self dataFrom: (self callToolWith: {
				         (#action -> 'listFiles').
				         (#includeEntryCounts -> false) } asDictionary).
	filePath := data at: #currentLogPath.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> filePath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryPathNotDirectory'.
	self assert: (error at: #directoryPath) equals: filePath
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReportsMissingDirectoryPath [

	| error missingPath result |
	missingPath := (FileLocator temp asFileReference
	                / ('mcp-missing-change-history-' , UUID new asString))
		               fullName.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> missingPath) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self
		assert: (error at: #errorCode)
		equals: 'ChangeHistoryDirectoryNotFound'.
	self assert: (error at: #directoryPath) equals: missingPath
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesReturnsCurrentHistoryFile [

	| data files result |
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#includeEntryCounts -> false) } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #action) equals: 'listFiles'.
	self assert: (data at: #currentLogPath) notNil.
	self assert: (data at: #directoryPath) notNil.
	self assert: files notEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ]).
	self assert: (files allSatisfy: [ :each |
			 (each includesKey: #path) and: [ each includesKey: #fileName ] ]).
	self assert: (files noneSatisfy: [ :each |
				 (each includesKey: #entriesCount) or: [
					 (each includesKey: #headReference) or: [
						 each includesKey: #loadError ] ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testListFilesSupportsDirectoryPath [

	| baseData data directoryPath files result |
	baseData := self dataFrom: (self callToolWith: {
				             (#action -> 'listFiles').
				             (#includeEntryCounts -> false) } asDictionary).
	directoryPath := baseData at: #directoryPath.
	result := self callToolWith: {
			          (#action -> 'listFiles').
			          (#directoryPath -> directoryPath).
			          (#includeEntryCounts -> false) } asDictionary.
	data := self dataFrom: result.
	files := data at: #files.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #action) equals: 'listFiles'.
	self assert: (data at: #directoryPath) equals: directoryPath.
	self assert: files notEmpty.
	self assert: (files anySatisfy: [ :each | each at: #isCurrent ])
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testNonCodeEntryDictionaryOmitsAbsentFields [

	| entry |
	entry := (MCPChangeHistoryEntryInfo fromEvent: EpSessionStart new)
		         asDictionary.
	self assert: (entry at: #eventClassName) equals: 'EpSessionStart'.
	self assert: (entry at: #summary) equals: 'an EpSessionStart'.
	self deny: (entry at: #isCodeChange).
	#( index reference globalName localName time triggerReference
	   packageName behaviorName classSide selector protocol ) do: [ :key |
		self deny: (entry includesKey: key) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testRevertEntriesRevertsConfirmedChanges [

	self withTemporaryRecoveryClassDo: [ :class |
		| data entryIndex result |
		entryIndex := self recordMethodAdditionOn: class.
		self assert: (class includesSelector: #rescuedValue).
		result := self callToolWith: {
				          (#action -> 'revertEntries').
				          (#indexes -> { entryIndex }).
				          (#confirm -> true) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #action) equals: 'revert'.
		self assert: (data at: #performed).
		self assert: (data at: #performedCount) equals: 1.
		self deny: (class includesSelector: #rescuedValue) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryTest >> testSelectionResultRequestsImageSaveOnlyAfterPerformedChanges [

	| confirmedResult emptyConfirmedResult previewResult tool |
	tool := MCPToolApplyChangeHistoryEntries new.
	previewResult := tool successResultText: 'preview' data: {
			                 (#action -> 'apply').
			                 (#performed -> false).
			                 (#performedCount -> 0) } asDictionary.
	emptyConfirmedResult := tool
		                        successResultText: 'empty apply'
		                        data: {
				                        (#action -> 'apply').
				                        (#performed -> true).
				                        (#performedCount -> 0) } asDictionary.
	confirmedResult := tool successResultText: 'confirmed apply' data: {
			                   (#action -> 'apply').
			                   (#performed -> true).
			                   (#performedCount -> 1) } asDictionary.

	self deny:
		(tool shouldSaveImageAfterSuccessfulExecutionForResult:
			 previewResult).
	self deny: (tool shouldSaveImageAfterSuccessfulExecutionForResult:
			 emptyConfirmedResult).
	self assert: (tool shouldSaveImageAfterSuccessfulExecutionForResult:
			 confirmedResult)

]

{ #category : 'private - calling' }
MCPToolChangeHistoryTest >> toolName [

	self shouldNotImplement
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
