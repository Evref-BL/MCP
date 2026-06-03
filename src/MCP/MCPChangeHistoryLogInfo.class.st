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

	^ {
		  (#path -> path).
		  (#fileName -> fileName).
		  (#storeName -> storeName).
		  (#exists -> exists).
		  (#fileSize -> fileSize).
		  (#modificationTime -> modificationTime).
		  (#entriesCount -> entriesCount).
		  (#headReference -> headReference).
		  (#isCurrent -> isCurrent).
		  (#loadError -> loadError) } asDictionary
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
		headReference := self stringFromReference: ([ log headReference ]
				                  on: Error
				                  do: [ :error | nil ]) ]
		on: Error
		do: [ :error |
		loadError := error messageText ifNil: [ error asString ] ]
]

{ #category : 'private' }
MCPChangeHistoryLogInfo >> stringFromReference: aReference [

	^ aReference ifNotNil: [ aReference shortName asString ]
]
