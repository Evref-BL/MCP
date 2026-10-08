"
Compact pagination result shared by list and search tools. It keeps MCP payloads small by carrying the current page entries and, only when another page exists, the offset to request the next page.
"
Class {
	#name : 'MCPPaginationResult',
	#superclass : 'MCPResult',
	#instVars : [
		'entries',
		'nextOffset',
		'totalCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPPaginationResult class >> entries: entryCollection nextOffset: anIntegerOrNil [

	^ self entries: entryCollection nextOffset: anIntegerOrNil totalCount: entryCollection size
]

{ #category : 'instance creation' }
MCPPaginationResult class >> entries: entryCollection nextOffset: anIntegerOrNil totalCount: totalCountInteger [

	^ self new
		  entries: entryCollection;
		  nextOffset: anIntegerOrNil;
		  totalCount: totalCountInteger;
		  yourself
]

{ #category : 'instance creation' }
MCPPaginationResult class >> fromEntries: entryCollection limit: limit offset: offset [

	| endIndex pageEntries startIndex |
	(limit = 0 or: [ offset >= entryCollection size ]) ifTrue: [
		^ self entries: #(  ) nextOffset: nil totalCount: entryCollection size ].
	startIndex := offset + 1.
	endIndex := entryCollection size min: offset + limit.
	pageEntries := (entryCollection copyFrom: startIndex to: endIndex) asArray.
	^ self
		  entries: pageEntries
		  nextOffset: (offset + pageEntries size < entryCollection size ifTrue: [ offset + pageEntries size ])
		  totalCount: entryCollection size
]

{ #category : 'converting' }
MCPPaginationResult >> asDictionary [

	^ self asDictionaryWithEntriesKey: #entries
]

{ #category : 'converting' }
MCPPaginationResult >> asDictionaryWithEntriesKey: entriesKey [

	| data |
	data := Dictionary new.
	data at: entriesKey put: self entries.
	data at: #pagination put: self paginationDictionary.
	self nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'accessing' }
MCPPaginationResult >> entries [

	^ entries ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPPaginationResult >> entries: aCollection [

	entries := aCollection ifNil: [ #(  ) ]
]

{ #category : 'testing' }
MCPPaginationResult >> hasMore [

	^ self nextOffset notNil
]

{ #category : 'accessing' }
MCPPaginationResult >> nextOffset [

	^ nextOffset
]

{ #category : 'accessing' }
MCPPaginationResult >> nextOffset: anIntegerOrNil [

	nextOffset := anIntegerOrNil
]

{ #category : 'converting' }
MCPPaginationResult >> paginationDictionary [

	| data |
	data := Dictionary new.
	data at: #returnedCount put: self returnedCount.
	data at: #totalCount put: self totalCount.
	data at: #truncated put: self truncated.
	self nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'accessing' }
MCPPaginationResult >> returnedCount [

	^ self entries size
]

{ #category : 'accessing' }
MCPPaginationResult >> totalCount [

	^ totalCount ifNil: [ self returnedCount ]
]

{ #category : 'accessing' }
MCPPaginationResult >> totalCount: anInteger [

	totalCount := anInteger
]

{ #category : 'accessing' }
MCPPaginationResult >> truncated [

	^ self hasMore
]
