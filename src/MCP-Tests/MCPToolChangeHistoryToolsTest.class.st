"
Tests change-history tool metadata, schemas, and result shapes.
"
Class {
	#name : 'MCPToolChangeHistoryToolsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
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
			self assert: metadata keys asSet equals: #( name description ) asSet ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testChangeHistoryToolsDeclareExpectedInputs [

	| applyProperties entryProperties fileProperties revertProperties selectionProperties |
	fileProperties := self inputPropertyNamesFor: MCPToolListChangeHistoryFiles new.
	entryProperties := self inputPropertyNamesFor: MCPToolListChangeHistoryEntries new.
	applyProperties := self inputPropertyNamesFor: MCPToolApplyChangeHistoryEntries new.
	revertProperties := self inputPropertyNamesFor: MCPToolRevertChangeHistoryEntries new.
	selectionProperties := #( 'directoryPath' 'historyFile' 'indexes' 'startIndex' 'endIndex' 'latestCount' 'codeChangesOnly'
	                          'confirm' ).
	self assert: fileProperties asArray equals: #( 'directoryPath' 'offset' ).
	self
		assert: entryProperties asArray
		equals: #( 'directoryPath' 'historyFile' 'offset' 'newestFirst' 'codeChangesOnly' ).
	self assert: applyProperties asArray equals: selectionProperties.
	self assert: revertProperties asArray equals: selectionProperties
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
	self assert: files notEmpty.
	self assert: (files allSatisfy: [ :each |
			 (each includesKey: #file) and: [ each keys allSatisfy: [ :key | allowedFileKeys includes: key ] ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testSelectionResultDataHasExpectedShape [

	| data result |
	result := MCPChangeHistorySelectionResult
		          action: 'apply'
		          historyFileName: 'memory.ombu'
		          selectionCriteria: Dictionary new
		          selectedEntries: #(  )
		          previewEntries: #(  )
		          skippedNonCodeChangeCount: 0
		          performed: false
		          performedCount: 0.
	data := result asDictionary.
	self assert: data equals: {
			(#action -> 'apply').
			(#historyFile -> 'memory.ombu').
			(#selectionCriteria -> Dictionary new).
			(#selectedEntries -> #(  )).
			(#previewEntries -> #(  )).
			(#selectedCount -> 0).
			(#selectedCodeChangeCount -> 0).
			(#previewCount -> 0).
			(#skippedNonCodeChangeCount -> 0).
			(#performed -> false).
			(#performedCount -> 0) } asDictionary
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testSelectionToolsRouteToChangeHistorySelectionCommand [

	{
		(MCPToolApplyChangeHistoryEntries -> 'applyEntries').
		(MCPToolRevertChangeHistoryEntries -> 'revertEntries') } do: [ :association |
			| command parsedRequest rawRequest tool |
			tool := association key new.
			rawRequest := tool requestFromToolCallArguments: { (#latestCount -> 1) } asDictionary.
			parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
			command := tool commandForRequest: parsedRequest.
			self assert: parsedRequest class equals: MCPChangeHistorySelectionRequest.
			self assert: parsedRequest operation equals: association value.
			self assert: command class equals: MCPChangeHistorySelectionCommand ]
]

{ #category : 'private' }
MCPToolChangeHistoryToolsTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom: (self callToolNamed: aToolName withArguments: arguments)
]
