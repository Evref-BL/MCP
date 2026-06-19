"
Result DTO for listing change history files and the directory that was scanned.
"
Class {
	#name : 'MCPChangeHistoryListLogsResult',
	#superclass : 'Object',
	#instVars : [
		'logs',
		'directoryPath',
		'nextOffset'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistoryListLogsResult class >> directoryPath: scannedPath page: aPage [

	^ self new
		  directoryPath: scannedPath;
		  logs: aPage entries;
		  nextOffset: aPage nextOffset;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryListLogsResult >> asDictionary [

	| data |
	data := Dictionary new.
	directoryPath ifNotNil: [ data at: #directoryPath put: directoryPath ].
	data
		at: #files
		put: ((self logs collect: [ :each | each asDictionary ]) as: Array).
	nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> directoryPath [

	^ directoryPath
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> directoryPath: aPath [

	directoryPath := aPath
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> logs [

	^ logs ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> logs: aCollection [

	logs := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> nextOffset [

	^ nextOffset
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> nextOffset: anIntegerOrNil [

	nextOffset := anIntegerOrNil
]
