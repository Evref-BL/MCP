"
Result DTO for listing entries from a change history source.
"
Class {
	#name : 'MCPChangeHistoryListEntriesResult',
	#superclass : 'Object',
	#instVars : [
		'historyFilePath',
		'entries',
		'totalCount',
		'limit',
		'offset',
		'newestFirst',
		'codeChangesOnly',
		'headReference'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistoryListEntriesResult class >> historyFilePath: aPath entries: entryInfos totalCount: total limit: aLimit offset: anOffset newestFirst: newestFirstFlag codeChangesOnly: codeChangesOnlyFlag headReference: aReferenceString [

	^ self new
		  historyFilePath: aPath;
		  entries: entryInfos;
		  totalCount: total;
		  limit: aLimit;
		  offset: anOffset;
		  newestFirst: newestFirstFlag;
		  codeChangesOnly: codeChangesOnlyFlag;
		  headReference: aReferenceString;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryListEntriesResult >> asDictionary [

	^ {
		  (#operation -> 'listEntries').
		  (#historyFilePath -> historyFilePath).
		  (#entries
		   ->
		   ((self entries collect: [ :each | each asDictionary ]) as: Array)).
		  (#totalCount -> totalCount).
		  (#limit -> limit).
		  (#offset -> offset).
		  (#newestFirst -> newestFirst).
		  (#codeChangesOnly -> codeChangesOnly).
		  (#headReference -> headReference) } asDictionary
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> codeChangesOnly: aBoolean [

	codeChangesOnly := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> entries [

	^ entries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> entries: aCollection [

	entries := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> headReference: aString [

	headReference := aString
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> historyFilePath: aPath [

	historyFilePath := aPath
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> newestFirst: aBoolean [

	newestFirst := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> offset: anInteger [

	offset := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> totalCount: anInteger [

	totalCount := anInteger
]
