"
Structured metadata for one change history file.
"
Class {
	#name : 'MCPChangeHistoryLogInfo',
	#superclass : 'Object',
	#instVars : [
		'path',
		'fileName',
		'storeName',
		'exists',
		'fileSize',
		'modificationTime',
		'entriesCount',
		'headReference',
		'isCurrent',
		'loadError'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPChangeHistoryLogInfo class >> fromFileReference: aFileReference isCurrent: aBoolean includeEntryCounts: includeCounts [

	^ self new
		  initializeFromFileReference: aFileReference
		  isCurrent: aBoolean
		  includeEntryCounts: includeCounts
]

{ #category : 'converting' }
MCPChangeHistoryLogInfo >> asDictionary [

	| data |
	data := Dictionary new.
	path ifNotNil: [ data at: #path put: path ].
	fileName ifNotNil: [ data at: #fileName put: fileName ].
	storeName ifNotNil: [ data at: #storeName put: storeName ].
	exists ifNotNil: [ data at: #exists put: exists ].
	fileSize ifNotNil: [ data at: #fileSize put: fileSize ].
	modificationTime ifNotNil: [
		data at: #modificationTime put: modificationTime ].
	entriesCount ifNotNil: [ data at: #entriesCount put: entriesCount ].
	headReference ifNotNil: [ data at: #headReference put: headReference ].
	isCurrent ifNotNil: [ data at: #isCurrent put: isCurrent ].
	loadError ifNotNil: [ data at: #loadError put: loadError ].
	^ data
]

{ #category : 'initialization' }
MCPChangeHistoryLogInfo >> initializeFromFileReference: aFileReference isCurrent: aBoolean includeEntryCounts: includeCounts [

	path := [ aFileReference fullName ]
		        on: Error
		        do: [ :error | aFileReference asString ].
	fileName := [ aFileReference basename ]
		            on: Error
		            do: [ :error | path ].
	storeName := fileName.
	exists := [ aFileReference exists ]
		          on: Error
		          do: [ :error | false ].
	fileSize := [ aFileReference size ]
		            on: Error
		            do: [ :error | nil ].
	modificationTime := [ aFileReference modificationTime asString ]
		                    on: Error
		                    do: [ :error | nil ].
	isCurrent := aBoolean.
	includeCounts ifTrue: [
		self loadEntryMetadataFromFileReference: aFileReference ]
]

{ #category : 'private' }
MCPChangeHistoryLogInfo >> loadEntryMetadataFromFileReference: aFileReference [

	[
		| log |
		log := EpLog freshFromFile: aFileReference.
		entriesCount := log entries size.
		headReference := self stringFromReference: log headReference ]
		on: Error
		do: [ :error |
		loadError := error messageText ifNil: [ error asString ] ]
]

{ #category : 'private' }
MCPChangeHistoryLogInfo >> stringFromReference: aReference [

	aReference isNull ifTrue: [ ^ nil ].
	^ aReference shortName asString
]
