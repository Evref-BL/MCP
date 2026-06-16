"
Compact pagination result shared by list and search tools. It keeps MCP payloads small by carrying the current page entries and, only when another page exists, the offset to request the next page.
"
Class {
	#name : 'MCPPaginationResult',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'nextOffset'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPPaginationResult class >> entries: entryCollection nextOffset: anIntegerOrNil [

	^ self new
		  entries: entryCollection;
		  nextOffset: anIntegerOrNil;
		  yourself
]

{ #category : 'instance creation' }
MCPPaginationResult class >> fromEntries: entryCollection limit: limit offset: offset [

	| endIndex pageEntries startIndex |
	(limit = 0 or: [ offset >= entryCollection size ]) ifTrue: [
		^ self entries: #(  ) nextOffset: nil ].
	startIndex := offset + 1.
	endIndex := entryCollection size min: offset + limit.
	pageEntries := (entryCollection copyFrom: startIndex to: endIndex)
		               asArray.
	^ self
		  entries: pageEntries
		  nextOffset:
			  (offset + pageEntries size < entryCollection size ifTrue: [
				   offset + pageEntries size ])
]

{ #category : 'converting' }
MCPPaginationResult >> asDictionaryWithEntriesKey: entriesKey [

	| data |
	data := Dictionary new.
	data at: entriesKey put: self entries.
	self nextOffset ifNotNil: [ :offset |
		data at: #nextOffset put: offset ].
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

{ #category : 'accessing' }
MCPPaginationResult >> nextOffset [

	^ nextOffset
]

{ #category : 'accessing' }
MCPPaginationResult >> nextOffset: anIntegerOrNil [

	nextOffset := anIntegerOrNil
]

{ #category : 'accessing' }
MCPPaginationResult >> returnedCount [

	^ self entries size
]
