Class {
	#name : 'MCPToolListChangeHistoryFiles',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> changeHistoryOperation [

	^ 'listFiles'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultName [

	^ 'list-change-history-files'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> defaultTitle [

	^ 'List Change History Files'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryFiles >> operationDescription [

	^ 'List available .ombu change-history files.'
]
