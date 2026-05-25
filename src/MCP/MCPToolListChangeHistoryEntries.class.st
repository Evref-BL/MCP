Class {
	#name : 'MCPToolListChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> changeHistoryOperation [

	^ 'listEntries'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultName [

	^ 'list-change-history-entries'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> defaultTitle [

	^ 'List Change History Entries'
]

{ #category : 'defaults' }
MCPToolListChangeHistoryEntries >> operationDescription [

	^ 'List entries in the current or selected .ombu change-history file.'
]
