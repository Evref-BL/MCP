"
MCP protocol structure for one document returned by resources/read.

Contents carry text under the URI they were read from.
"
Class {
	#name : 'MCPStructureResourceContents',
	#superclass : 'Object',
	#instVars : [
		'uri',
		'mimeType',
		'text'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructureResourceContents class >> uri: aUri text: aString mimeType: aMimeType [

	^ self new
		  uri: aUri;
		  text: aString;
		  mimeType: aMimeType;
		  yourself
]

{ #category : 'converting' }
MCPStructureResourceContents >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new
		              at: #uri put: self uri asJRPCJSON;
		              yourself.
	self mimeType ifNotNil: [ :value | dictionary at: #mimeType put: value asJRPCJSON ].
	self text ifNotNil: [ :value | dictionary at: #text put: value asJRPCJSON ].
	^ dictionary
]

{ #category : 'accessing' }
MCPStructureResourceContents >> mimeType [

	^ mimeType
]

{ #category : 'accessing' }
MCPStructureResourceContents >> mimeType: anObject [

	mimeType := anObject
]

{ #category : 'accessing' }
MCPStructureResourceContents >> text [

	^ text
]

{ #category : 'accessing' }
MCPStructureResourceContents >> text: anObject [

	text := anObject
]

{ #category : 'accessing' }
MCPStructureResourceContents >> uri [

	^ uri
]

{ #category : 'accessing' }
MCPStructureResourceContents >> uri: anObject [

	uri := anObject
]
