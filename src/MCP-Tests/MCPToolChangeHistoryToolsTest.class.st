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
MCPToolChangeHistoryToolsTest >> testChangeHistoryToolsAreDiscoverableWithExpectedRisk [

	| metadataByName result toolNames |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#group -> 'history') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	toolNames := metadataByName keys.
	#( 'history_file_list' 'history_entry_list' 'history_entry_apply'
	   'history_entry_revert' ) do: [ :toolName |
			| metadata tool |
			self assert: (toolNames includes: toolName).
			tool := MCPToolRegistry
				        toolNamed: toolName
				        ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self
				assert: (MCPToolRegistry exposureForTool: tool)
				equals: 'discoverable'.
			metadata := metadataByName at: toolName.
			self
				assert: metadata keys asSet
				equals: #( name description schemaInspectionRequired ) asSet.
			self assert: (metadata at: #schemaInspectionRequired) ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testChangeHistoryToolsDeclareExpectedInputs [

	| applyProperties entryProperties fileProperties revertProperties selectionProperties |
	fileProperties := self inputPropertyNamesFor:
		                  MCPToolListChangeHistoryFiles new.
	entryProperties := self inputPropertyNamesFor:
		                   MCPToolListChangeHistoryEntries new.
	applyProperties := self inputPropertyNamesFor:
		                   MCPToolApplyChangeHistoryEntries new.
	revertProperties := self inputPropertyNamesFor:
		                    MCPToolRevertChangeHistoryEntries new.
	selectionProperties := #( 'directoryPath' 'historyFileName'
	                          'indexes' 'startIndex' 'endIndex'
	                          'latestCount' 'codeChangesOnly'
	                          'confirm' ).
	self
		assert: fileProperties asArray
		equals: #( 'directoryPath' 'limit' 'offset' ).
	self
		assert: entryProperties asArray
		equals:
			#( 'directoryPath' 'historyFileName' 'limit' 'offset' 'newestFirst'
			   'codeChangesOnly' ).
	self assert: applyProperties asArray equals: selectionProperties.
	self assert: revertProperties asArray equals: selectionProperties
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryEntriesReturnsEntries [

	| data |
	data := self toolNamed: 'history_entry_list' dataFromArguments: {
			        (#limit -> 3).
			        (#newestFirst -> true) } asDictionary.
	self assert: (data includesKey: #entries).
	self assert: (data at: #entries) size <= 3
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryFilesPaginatesFiles [

	| data directory files nextOffset |
	directory := FileLocator temp asFileReference
	             / ('mcp-history-files-' , UUID new asString).
	[
		directory ensureCreateDirectory.
		directory / 'a.ombu' writeStreamDo: [ :stream |
			stream nextPutAll: 'a' ].
		directory / 'b.ombu' writeStreamDo: [ :stream |
			stream nextPutAll: 'b' ].
		data := self toolNamed: 'history_file_list' dataFromArguments: {
				        (#directoryPath -> directory fullName).
				        (#limit -> 1) } asDictionary.
		files := data at: #files.
		nextOffset := data at: #nextOffset.
		self assert: files size equals: 1.
		self assert: nextOffset equals: 1 ] ensure: [
		directory ensureDeleteAll ]
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryFilesReturnsFiles [

	| allowedFileKeys data files |
	data := self
		        toolNamed: 'history_file_list'
		        dataFromArguments: Dictionary new.
	files := data at: #files.
	allowedFileKeys := #( fileName exists fileSize modificationTime
	                      isCurrent ) asSet.
	self assert: (data includesKey: #directoryPath).
	self assert: files notEmpty.
	self assert: (files allSatisfy: [ :each |
				 (each includesKey: #fileName) and: [
					 each keys allSatisfy: [ :key | allowedFileKeys includes: key ] ] ])
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testSelectionResultDataUsesActionNotOperation [

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
	self assert: (data at: #action) equals: 'apply'.
	self assert: (data at: #historyFileName) equals: 'memory.ombu'.
	self deny: (data includesKey: #operation)
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testSelectionToolsRouteToChangeHistorySelectionCommand [

	{
		(MCPToolApplyChangeHistoryEntries -> 'applyEntries').
		(MCPToolRevertChangeHistoryEntries -> 'revertEntries') } do: [
			:association |
			| command parsedRequest rawRequest tool |
			tool := association key new.
			rawRequest := tool requestFromToolCallArguments:
				              { (#latestCount -> 1) } asDictionary.
			parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
			command := tool commandForRequest: parsedRequest.
			self
				assert: parsedRequest class
				equals: MCPChangeHistorySelectionRequest.
			self assert: parsedRequest operation equals: association value.
			self assert: command class equals: MCPChangeHistorySelectionCommand ]
]

{ #category : 'private' }
MCPToolChangeHistoryToolsTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom:
		  (self callToolNamed: aToolName withArguments: arguments)
]
