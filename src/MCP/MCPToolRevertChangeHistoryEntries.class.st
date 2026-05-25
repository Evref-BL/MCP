Class {
	#name : 'MCPToolRevertChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries >> changeHistoryOperation [

	^ 'revertEntries'
]

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries >> defaultName [

	^ 'revert-change-history-entries'
]

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries >> defaultTitle [

	^ 'Revert Change History Entries'
]

{ #category : 'defaults' }
MCPToolRevertChangeHistoryEntries >> operationDescription [

	^ 'Preview or revert selected code changes from change history.'
]
