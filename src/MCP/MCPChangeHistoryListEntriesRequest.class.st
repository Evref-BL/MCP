"
Request for listing entries from the current image change history or from a specific history file.
"
Class {
	#name : 'MCPChangeHistoryListEntriesRequest',
	#superclass : 'Object',
	#instVars : [
		'directoryPath',
		'historyFileName',
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
		  directoryPath: (request stringArgumentNamed: 'directoryPath');
		  historyFileName: (request stringArgumentNamed: 'historyFileName');
		  limit: (request nonNegativeIntegerArgumentNamed: 'limit' default: aTool defaultEntryLimit);
		  offset: (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  newestFirst: (request booleanArgumentNamed: 'newestFirst' default: false);
		  codeChangesOnly: (request booleanArgumentNamed: 'codeChangesOnly' default: false);
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
MCPChangeHistoryListEntriesRequest >> directoryPath [

	^ directoryPath
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> directoryPath: aString [

	directoryPath := aString
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> historyFileName [

	^ historyFileName
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> historyFileName: aString [

	historyFileName := aString
]

{ #category : 'accessing' }
MCPChangeHistoryListEntriesRequest >> limit [

	^ limit ifNil: [ 25 ]
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
