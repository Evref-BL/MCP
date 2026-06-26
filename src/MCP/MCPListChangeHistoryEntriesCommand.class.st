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

	| entryInfos fileName log logAndFileName page resultPage |
	logAndFileName := self
		                  logAndFileNameFromDirectoryPath:
		                  request directoryPath
		                  fileName: request historyFileName.
	log := logAndFileName first.
	fileName := logAndFileName second.
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
	^ MCPChangeHistoryListEntriesResult
		  historyFileName: fileName
		  page: resultPage
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
