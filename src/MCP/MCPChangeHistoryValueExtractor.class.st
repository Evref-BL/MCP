"
Extracts optional string fields from Epicea change-history objects and references.

This is an explicit boundary adapter for Epicea objects whose protocol varies across event/reference kinds. It keeps optional external protocol handling out of DTO and command code.
"
Class {
	#name : 'MCPChangeHistoryValueExtractor',
	#superclass : 'Object',
	#category : 'MCP-Utilities',
	#package : 'MCP',
	#tag : 'Utilities'
}

{ #category : 'accessing' }
MCPChangeHistoryValueExtractor class >> referenceStringFrom: aReference [

	aReference ifNil: [ ^ nil ].
	^ aReference mcpChangeHistoryReferenceString
]

{ #category : 'accessing' }
MCPChangeHistoryValueExtractor class >> stringValueFrom: anObject selector: aSelector [

	anObject ifNil: [ ^ nil ].
	^ (self valueFrom: anObject selector: aSelector) ifNotNil: [ :value |
		  value asString ]
]

{ #category : 'private' }
MCPChangeHistoryValueExtractor class >> valueFrom: anObject selector: aSelector [

	^ anObject mcpChangeHistoryValueForSelector: aSelector
]
