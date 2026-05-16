"
Request for listing entries from the current image change history or from a specific history file.
"
Class {
	#name : 'MCPChangeHistoryListEntriesRequest',
	#superclass : 'Object',
	#instVars : [
		'historyFilePath',
		'limit',
		'offset',
		'newestFirst',
		'codeChangesOnly'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPChangeHistoryListEntriesRequest class >> fromRequest: request tool: aTool [

	^ self new
		  historyFilePath: (request stringArgumentNamed: 'historyFilePath');
		  limit:
			  (request nonNegativeIntegerArgumentNamed: 'limit' default: 100);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  newestFirst:
			  (request booleanArgumentNamed: 'newestFirst' default: false);
		  codeChangesOnly:
			  (request booleanArgumentNamed: 'codeChangesOnly' default: false);
		  yourself
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> codeChangesOnly [

	^ codeChangesOnly ifNil: [ false ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> codeChangesOnly: aBoolean [

	codeChangesOnly := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> historyFilePath [

	^ historyFilePath
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> historyFilePath: aString [

	historyFilePath := aString
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> limit [

	^ limit ifNil: [ 100 ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> newestFirst [

	^ newestFirst ifNil: [ false ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> newestFirst: aBoolean [

	newestFirst := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> offset [

	^ offset ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> offset: anInteger [

	offset := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> operation [

	^ 'listEntries'
]
