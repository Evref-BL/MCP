"
Result DTO for listing entries from a change history source.
"
Class {
	#name : 'MCPChangeHistoryListEntriesResult',
	#superclass : 'MCPResult',
	#instVars : [
		'historyFileName',
		'entries',
		'nextOffset'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistoryListEntriesResult class >> historyFileName: aString page: aPage [

	^ self new
		  historyFileName: aString;
		  entries: aPage entries;
		  nextOffset: aPage nextOffset;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryListEntriesResult >> asDictionary [

	| data |
	data := Dictionary new.
	historyFileName ifNotNil: [
		data at: #historyFileName put: historyFileName ].
	data
		at: #entries
		put:
		((self entries collect: [ :each | each asDictionary ]) as: Array).
	self nextOffset ifNotNil: [ :offset |
		data at: #nextOffset put: offset ].
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
MCPChangeHistoryListEntriesResult >> historyFileName: aString [

	historyFileName := aString
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> nextOffset [

	^ nextOffset
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesResult >> nextOffset: anIntegerOrNil [

	nextOffset := anIntegerOrNil
]
