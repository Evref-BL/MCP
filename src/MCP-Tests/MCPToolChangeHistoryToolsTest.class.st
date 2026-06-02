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
	#( 'history_file_list' 'history_entry_list' ) do: [ :toolName |
			| metadata |
			self assert: (toolNames includes: toolName).
			metadata := metadataByName at: toolName.
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #mutability) equals: 'read'.
			self assert: (metadata at: #risk) equals: 'low' ].
	#( 'history_entry_apply' 'history_entry_revert' ) do: [ :toolName |
			| metadata |
			self assert: (toolNames includes: toolName).
			metadata := metadataByName at: toolName.
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #mutability) equals: 'write'.
			self assert: (metadata at: #risk) equals: 'high' ]
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
	selectionProperties := #( 'historyFilePath' 'indexes' 'entryReferences'
	                          'startIndex' 'endIndex' 'latestCount'
	                          'codeChangesOnly' 'confirm' ).
	self
		assert: fileProperties asArray
		equals: #( 'includeEntryCounts' 'directoryPath' ).
	self
		assert: entryProperties asArray
		equals:
		#( 'historyFilePath' 'limit' 'offset' 'newestFirst' 'codeChangesOnly' ).
	self assert: applyProperties asArray equals: selectionProperties.
	self assert: revertProperties asArray equals: selectionProperties
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryEntriesReturnsEntries [

	| data |
	data := self toolNamed: 'history_entry_list' dataFromArguments: {
			        (#limit -> 3).
			        (#newestFirst -> true) } asDictionary.
	self assert: (data at: #action) equals: 'listEntries'.
	self assert: (data includesKey: #totalCount).
	self assert: (data includesKey: #entries)
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testListChangeHistoryFilesReturnsFiles [

	| data |
	data := self
		        toolNamed: 'history_file_list'
		        dataFromArguments:
		        { (#includeEntryCounts -> false) } asDictionary.
	self assert: (data at: #action) equals: 'listFiles'.
	self assert: (data includesKey: #currentLogPath).
	self assert: (data includesKey: #directoryPath).
	self assert: (data includesKey: #files)
]

{ #category : 'tests' }
MCPToolChangeHistoryToolsTest >> testSelectionResultDataUsesActionNotOperation [

	| data result |
	result := MCPChangeHistorySelectionResult
		          action: 'apply'
		          historyFilePath: 'memory.ombu'
		          selectionCriteria: Dictionary new
		          selectedEntries: #(  )
		          previewEntries: #(  )
		          skippedNonCodeChangeCount: 0
		          performed: false
		          performedCount: 0
		          headReference: nil.
	data := result asDictionary.
	self assert: (data at: #action) equals: 'apply'.
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
