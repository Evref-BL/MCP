Class {
	#name : 'MCPToolFocusedChangeHistoryTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFocusedChangeHistoryTest >> inputPropertyNamesFor: aTool [

	^ aTool inputSchema properties collect: [ :each | each name ]
]

{ #category : 'tests' }
MCPToolFocusedChangeHistoryTest >> testFindChangeHistoryEntriesMatchesLegacyListEntries [

	| arguments focusedData legacyData |
	arguments := {
		             (#limit -> 3).
		             (#newestFirst -> true) } asDictionary.
	focusedData := self
		               toolNamed: 'history_entry_list'
		               dataFromArguments: arguments.
	legacyData := self
		              toolNamed: 'history_entry_manage'
		              dataFromArguments: (arguments copy
				               at: #operation put: 'listEntries';
				               yourself).
	self assert: (focusedData at: #operation) equals: 'listEntries'.
	self
		assert: (focusedData at: #totalCount)
		equals: (legacyData at: #totalCount).
	self
		assert: (focusedData at: #entries)
		equals: (legacyData at: #entries)
]

{ #category : 'tests' }
MCPToolFocusedChangeHistoryTest >> testFindChangeHistoryFilesMatchesLegacyListFiles [

	| arguments focusedData legacyData |
	arguments := { (#includeEntryCounts -> false) } asDictionary.
	focusedData := self
		               toolNamed: 'history_file_list'
		               dataFromArguments: arguments.
	legacyData := self
		              toolNamed: 'history_entry_manage'
		              dataFromArguments: (arguments copy
				               at: #operation put: 'listFiles';
				               yourself).
	self assert: (focusedData at: #operation) equals: 'listFiles'.
	self
		assert: (focusedData at: #currentLogPath)
		equals: (legacyData at: #currentLogPath).
	self
		assert: (focusedData at: #directoryPath)
		equals: (legacyData at: #directoryPath).
	self assert: (focusedData at: #files) equals: (legacyData at: #files)
]

{ #category : 'tests' }
MCPToolFocusedChangeHistoryTest >> testFocusedChangeHistorySchemasOmitOperationAndMutatingInputs [

	| entryProperties fileProperties |
	fileProperties := self inputPropertyNamesFor:
		                  MCPToolFindChangeHistoryFiles new.
	entryProperties := self inputPropertyNamesFor:
		                   MCPToolFindChangeHistoryEntries new.
	self
		assert: fileProperties asArray
		equals: #( 'includeEntryCounts' 'directoryPath' ).
	self
		assert: entryProperties asArray
		equals:
		#( 'historyFilePath' 'limit' 'offset' 'newestFirst' 'codeChangesOnly' ).
	#( 'operation' 'confirm' 'indexes' 'entryReferences'
	   'startIndex' 'endIndex' 'latestCount' ) do: [ :each |
			self deny: (fileProperties includes: each).
			self deny: (entryProperties includes: each) ]
]

{ #category : 'tests' }
MCPToolFocusedChangeHistoryTest >> testFocusedChangeHistoryToolsAreDiscoverableReadLowRisk [

	| metadataByName result toolNames |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#group -> 'history') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	toolNames := metadataByName keys.
	#( 'history_file_list' 'history_entry_list' ) do: [
			:toolName |
			| metadata |
			self assert: (toolNames includes: toolName).
			metadata := metadataByName at: toolName.
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #mutability) equals: 'read'.
			self assert: (metadata at: #risk) equals: 'low' ].
	self assert: (metadataByName includesKey: 'history_entry_manage')
]

{ #category : 'private' }
MCPToolFocusedChangeHistoryTest >> toolNamed: aToolName dataFromArguments: arguments [

	^ self dataFrom:
		  (self callToolNamed: aToolName withArguments: arguments)
]
