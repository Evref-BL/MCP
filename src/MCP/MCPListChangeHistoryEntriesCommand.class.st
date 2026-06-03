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

	| logAndPath log path pairs page entryInfos headReference |
	logAndPath := self logAndPathForRequest.
	log := logAndPath first.
	path := logAndPath second.
	pairs := self matchingEntryPairsFrom: log.
	page := self
		        pageFrom: pairs
		        offset: request offset
		        limit: request limit.
	entryInfos := page collect: [ :pair |
			              MCPChangeHistoryEntryInfo
				              fromEntry: pair second
				              index: pair first
				              log: log ].
	headReference := self referenceStringFor: log headReference.
	^ MCPChangeHistoryListEntriesResult
		  historyFilePath: path
		  entries: entryInfos
		  totalCount: pairs size
		  limit: request limit
		  offset: request offset
		  newestFirst: request newestFirst
		  codeChangesOnly: request codeChangesOnly
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

	| start stop |
	aLimit = 0 ifTrue: [ ^ #(  ) ].
	anOffset >= entryPairs size ifTrue: [ ^ #(  ) ].
	start := anOffset + 1.
	stop := anOffset + aLimit min: entryPairs size.
	^ entryPairs copyFrom: start to: stop
]
