"
Command that lists granular entries from image change history.
"
Class {
	#name : 'MCPListChangeHistoryEntriesCommand',
	#superclass : 'MCPChangeHistoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'execution' }
MCPListChangeHistoryEntriesCommand >> execute [

	| entryInfos headReference log logAndPath page path resultPage |
	logAndPath := self logAndPathForRequest.
	log := logAndPath first.
	path := logAndPath second.
	page := self
		        pageFrom: (self matchingEntryPairsFrom: log)
		        offset: request offset
		        limit: request limit.
	entryInfos := page entries collect: [ :pair |
			              MCPChangeHistoryEntryInfo
				              fromEntry: pair second
				              index: pair first
				              log: log ].
	resultPage := MCPPaginationResult
		              entries: entryInfos
		              nextOffset: page nextOffset.
	headReference := self referenceStringFor: log headReference.
	^ MCPChangeHistoryListEntriesResult
		  historyFilePath: path
		  page: resultPage
		  headReference: headReference
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> isCurrentHistoryFilePath: aPathString [

	| currentFile requestedFile |
	currentFile := self currentHistoryFileReference.
	currentFile ifNil: [ ^ false ].
	requestedFile := aPathString asFileReference.
	^ requestedFile fullName = currentFile fullName
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> logAndPathForRequest [

	request historyFilePath ifNil: [ ^ self currentLogAndPath ].
	(self isCurrentHistoryFilePath: request historyFilePath) ifTrue: [
		^ self currentLogAndPath ].
	^ self logAndPathFromFilePath: request historyFilePath
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> matchingEntryPairsFrom: aLog [

	| pairs |
	pairs := OrderedCollection new.
	aLog entries doWithIndex: [ :entry :index |
		(request codeChangesOnly not or: [ self isCodeChangeEntry: entry ])
			ifTrue: [
				pairs add: {
						index.
						entry } ] ].
	request newestFirst ifTrue: [ ^ pairs reversed asOrderedCollection ].
	^ pairs
]

{ #category : 'private' }
MCPListChangeHistoryEntriesCommand >> pageFrom: entryPairs offset: anOffset limit: aLimit [

	^ MCPPaginationResult
		  fromEntries: entryPairs
		  limit: aLimit
		  offset: anOffset
]
