"
Request for listing .ombu change history files from the current image history directory or an explicit directory path.
"
Class {
	#name : 'MCPChangeHistoryListLogsRequest',
	#superclass : 'Object',
	#instVars : [
		'includeEntryCounts',
		'directoryPath',
		'limit',
		'offset'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPChangeHistoryListLogsRequest class >> fromRequest: request tool: aTool [

	^ self new
		  includeEntryCounts:
			  (request
				   booleanArgumentNamed: 'includeEntryCounts'
				   default: false);
		  directoryPath: (request stringArgumentNamed: 'directoryPath');
		  limit: (request
				   nonNegativeIntegerArgumentNamed: 'limit'
				   default: aTool defaultFileLimit
				   maximum: aTool maximumFileLimit);
		  offset:
			  (request nonNegativeIntegerArgumentNamed: 'offset' default: 0);
		  yourself
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> directoryPath [

	^ directoryPath
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> directoryPath: aPathString [

	directoryPath := aPathString
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> includeEntryCounts [

	^ includeEntryCounts ifNil: [ false ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> includeEntryCounts: aBoolean [

	includeEntryCounts := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> limit [

	^ limit ifNil: [ 25 ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> limit: anInteger [

	limit := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> offset [

	^ offset ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> offset: anInteger [

	offset := anInteger
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> operation [

	^ 'listFiles'
]
