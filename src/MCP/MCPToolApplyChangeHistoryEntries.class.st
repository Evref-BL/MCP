Class {
	#name : 'MCPToolApplyChangeHistoryEntries',
	#superclass : 'MCPToolChangeHistoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolApplyChangeHistoryEntries >> changeHistoryOperation [

	^ 'applyEntries'
]

{ #category : 'defaults' }
MCPToolApplyChangeHistoryEntries >> defaultName [

	^ 'apply-change-history-entries'
]

{ #category : 'defaults' }
MCPToolApplyChangeHistoryEntries >> defaultTitle [

	^ 'Apply Change History Entries'
]

{ #category : 'defaults' }
MCPToolApplyChangeHistoryEntries >> operationDescription [

	^ 'Preview or apply selected code changes from change history.'
]
