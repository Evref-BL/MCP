"
Tests change-history tool metadata, schemas, and result shapes.
"
Class {
	#name : 'MCPToolChangeHistoryToolsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolChangeHistoryToolsTest >> inputPropertyNamesFor: aTool [

	^ aTool inputSchema properties collect: [ :each | each name ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testChangeHistoryToolsAreDiscoverableWithExpectedMetadata [

	| metadataByName result toolNames |
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'history') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [ :each | (each at: #name) -> each ]) asDictionary.
	toolNames := metadataByName keys.
	#( 'history_file_list' 'history_entry_list' 'history_entry_apply' 'history_entry_revert' ) do: [ :toolName |
			| metadata tool |
			self assert: (toolNames includes: toolName).
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self assert: tool defaultExposure equals: 'discoverable'.
			metadata := metadataByName at: toolName.
			self assert: metadata keys asSet equals: #( name description exposure arguments requiredArguments ) asSet.
			self assert: (metadata at: #exposure) equals: 'discoverable' ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testChangeHistoryToolsDeclareExpectedInputs [

	| applyProperties entryProperties fileProperties revertProperties selectionProperties |
	fileProperties := self inputPropertyNamesFor: MCPToolListChangeHistoryFiles new.
	entryProperties := self inputPropertyNamesFor: MCPToolListChangeHistoryEntries new.
	applyProperties := self inputPropertyNamesFor: MCPToolApplyChangeHistoryEntries new.
	revertProperties := self inputPropertyNamesFor: MCPToolRevertChangeHistoryEntries new.
	selectionProperties := #( 'directoryPath' 'historyFile' 'indexes' 'codeChangesOnly' ).
	self assert: fileProperties asArray equals: #( 'directoryPath' 'offset' ).
	self
		assert: entryProperties asArray
		equals:
		#( 'directoryPath' 'historyFile' 'class' 'side' 'selector' 'startIndex' 'endIndex' 'offset' 'newestFirst' 'codeChangesOnly' ).
	self assert: applyProperties asArray equals: selectionProperties.
	self assert: revertProperties asArray equals: selectionProperties.
	{
		MCPToolApplyChangeHistoryEntries.
		MCPToolRevertChangeHistoryEntries } do: [ :toolClass |
		self assert: toolClass new inputSchema required asArray equals: #( 'indexes' ) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryEntriesReturnsEntries [

	| data |
	data := self toolNamed: 'history_entry_list' dataFromArguments: { (#newestFirst -> true) } asDictionary.
	self assert: (data includesKey: #entries).
	self assert: (data at: #entries) size <= MCPToolListChangeHistoryEntries new defaultPageLimit
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryFilesPaginatesFiles [

	| data directory files |
	directory := FileLocator temp asFileReference / ('mcp-history-files-' , UUID new asString).
	[
		directory ensureCreateDirectory.
		directory / 'a.ombu' writeStreamDo: [ :stream | stream nextPutAll: 'a' ].
		directory / 'b.ombu' writeStreamDo: [ :stream | stream nextPutAll: 'b' ].
		data := self toolNamed: 'history_file_list' dataFromArguments: {
			        (#directoryPath -> directory fullName).
			        (#offset -> 1) } asDictionary.
		files := data at: #files.
		self assert: files size equals: 1.
		self deny: (data includesKey: #nextOffset) ] ensure: [ directory ensureDeleteAll ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryFilesReturnsFiles [

	| allowedFileKeys data files |
	data := self toolNamed: 'history_file_list' dataFromArguments: Dictionary new.
	files := data at: #files.
	allowedFileKeys := #( file exists fileSize modificationTime isCurrent ) asSet.
	self assert: files isNotEmpty.
	self assert: (files allSatisfy: [ :each |
			 (each includesKey: #file) and: [ each keys allSatisfy: [ :key | allowedFileKeys includes: key ] ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListSaysWhereTheNextPageStarts [
	"A page of entries or files names the offset of the next, in the words every other paged answer uses: the text leaves nextOffset to the summary."

	| entries files |
	entries := MCPToolListChangeHistoryEntries new.
	self
		assert: (entries successSummaryForData: {
					 (#entries -> (1 to: 25) asArray).
					 (#nextOffset -> 25) } asDictionary)
		equals: 'Listed 25 change history entries. Next page: offset 25.'.
	self assert: (entries successSummaryForData: { (#entries -> #( 1 )) } asDictionary) equals: 'Listed 1 change history entry.'.
	files := MCPToolListChangeHistoryFiles new.
	self
		assert: (files successSummaryForData: {
					 (#files -> (1 to: 25) asArray).
					 (#nextOffset -> 25) } asDictionary)
		equals: 'Listed 25 change history files. Next page: offset 25.'.
	self assert: (files successSummaryForData: { (#files -> #( 1 )) } asDictionary) equals: 'Listed 1 change history file.'
]

{ #category : 'private' }
MCPToolChangeHistoryToolsTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom: (self callToolNamed: aToolName withArguments: arguments)
]
