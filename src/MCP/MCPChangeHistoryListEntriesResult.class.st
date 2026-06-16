"
Result DTO for listing entries from a change history source.
"
Class {
	#name : 'MCPChangeHistoryListEntriesResult',
	#superclass : 'Object',
	#instVars : [
		'historyFilePath',
		'entries',
		'nextOffset',
		'headReference'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistoryListEntriesResult class >> historyFilePath: aPath page: aPage headReference: aReferenceString [

	^ self new
		  historyFilePath: aPath;
		  entries: aPage entries;
		  nextOffset: aPage nextOffset;
		  headReference: aReferenceString;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryListEntriesResult >> asDictionary [

	| data |
	data := Dictionary new.
	data
		at: #entries
		put:
		((self entries collect: [ :each | each asDictionary ]) as: Array).
	historyFilePath ifNotNil: [
		data at: #historyFilePath put: historyFilePath ].
	self nextOffset ifNotNil: [ :offset |
		data at: #nextOffset put: offset ].
	headReference ifNotNil: [ data at: #headReference put: headReference ].
	^ data
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
MCPChangeHistoryListEntriesResult >> nextOffset [

	^ nextOffset
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> nextOffset: anIntegerOrNil [

	nextOffset := anIntegerOrNil
]
