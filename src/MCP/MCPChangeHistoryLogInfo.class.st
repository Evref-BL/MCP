"
Structured metadata for one change history file.
"
Class {
	#name : 'MCPChangeHistoryLogInfo',
	#superclass : 'Object',
	#instVars : [
		'path',
		'exists',
		'fileSize',
		'modificationTime',
		'isCurrent'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPChangeHistoryLogInfo class >> fromFileReference: aFileReference isCurrent: aBoolean [

	^ self new
		  initializeFromFileReference: aFileReference isCurrent: aBoolean;
		  yourself
]

{ #category : 'converting' }
MCPChangeHistoryLogInfo >> asDictionary [

	| data |
	data := Dictionary new.
	path ifNotNil: [ data at: #path put: path ].
	exists == false ifTrue: [ data at: #exists put: false ].
	fileSize ifNotNil: [ data at: #fileSize put: fileSize ].
	modificationTime ifNotNil: [
		data at: #modificationTime put: modificationTime ].
	isCurrent == true ifTrue: [ data at: #isCurrent put: true ].
	^ data
]

{ #category : 'initialization' }
MCPChangeHistoryLogInfo >> initializeFromFileReference: aFileReference isCurrent: aBoolean [

	path := [ aFileReference fullName ]
		        on: Error
		        do: [ :error | aFileReference asString ].
	exists := [ aFileReference exists ]
		          on: Error
		          do: [ :error | false ].
	fileSize := [ aFileReference size ]
		            on: Error
		            do: [ :error | nil ].
	modificationTime := [ aFileReference modificationTime asString ]
		                    on: Error
		                    do: [ :error | nil ].
	isCurrent := aBoolean
]
