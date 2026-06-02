"
Result DTO for listing change history files and the directory that was scanned.
"
Class {
	#name : 'MCPChangeHistoryListLogsResult',
	#superclass : 'Object',
	#instVars : [
		'currentLogPath',
		'logs',
		'directoryPath'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPChangeHistoryListLogsResult class >> currentLogPath: currentPath directoryPath: scannedPath logs: logInfos [

	^ self new
		  currentLogPath: currentPath;
		  directoryPath: scannedPath;
		  logs: logInfos;
		  yourself
]

{ #category : 'instance creation' }
MCPChangeHistoryListLogsResult class >> currentLogPath: aPath logs: logInfos [

	^ self new
		  currentLogPath: aPath;
		  logs: logInfos;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryListLogsResult >> asDictionary [

	^ {
		  (#action -> 'listFiles').
		  (#currentLogPath -> self currentLogPath).
		  (#directoryPath -> self directoryPath).
		  (#files
		   -> ((self logs collect: [ :each | each asDictionary ]) as: Array)) }
		  asDictionary
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> currentLogPath [

	^ currentLogPath
]

{ #category : 'accessing' }
MCPChangeHistoryListLogsResult >> currentLogPath: aPath [

	currentLogPath := aPath
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
