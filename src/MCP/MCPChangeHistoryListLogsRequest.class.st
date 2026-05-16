"
Request for listing .ombu change history files from the current image history directory or an explicit directory path.
"
Class {
	#name : 'MCPChangeHistoryListLogsRequest',
	#superclass : 'Object',
	#instVars : [
		'includeEntryCounts',
		'directoryPath'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPChangeHistoryListLogsRequest class >> fromRequest: request tool: aTool [

	^ self new
		  includeEntryCounts:
			  (request booleanArgumentNamed: 'includeEntryCounts' default: true);
		  directoryPath: (request stringArgumentNamed: 'directoryPath');
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

	^ includeEntryCounts ifNil: [ true ]
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> includeEntryCounts: aBoolean [

	includeEntryCounts := aBoolean
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsRequest >> operation [

	^ 'listFiles'
]
