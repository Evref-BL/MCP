"
MCP protocol structure for an image content block.

The MCP protocol carries image content as base64-encoded bytes plus a MIME type. Tools use me when the result should be directly renderable by MCP clients rather than merely referenced by a file path.
"
Class {
	#name : 'MCPStructureImageContent',
	#superclass : 'MCPStructureContentBlock',
	#instVars : [
		'data',
		'mimeType'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructureImageContent class >> data: base64Data mimeType: aMimeType [

	^ self new
		  data: base64Data;
		  mimeType: aMimeType;
		  yourself
]

{ #category : 'instance creation' }
MCPStructureImageContent class >> pngFromForm: aForm [
	"Encode a Pharo Form as an MCP image content block."

	| bytes |
	bytes := ByteArray streamContents: [ :stream |
		         PNGReadWriter putForm: aForm onStream: stream ].
	^ self data: bytes base64Encoded mimeType: 'image/png'
]

{ #category : 'accessing' }
MCPStructureImageContent >> asJRPCJSON [

	| dic |
	dic := super asJRPCJSON.
	self data ifNotNil: [ :base64Data |
		dic at: #data put: base64Data asJRPCJSON ].
	self mimeType ifNotNil: [ :typeString |
		dic at: #mimeType put: typeString asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureImageContent >> data [

	^ data
]

{ #category : 'accessing' }
MCPStructureImageContent >> data: aString [

	data := aString
]

{ #category : 'initialization' }
MCPStructureImageContent >> initialize [

	super initialize.
	type := 'image'
]

{ #category : 'accessing' }
MCPStructureImageContent >> mimeType [

	^ mimeType
]

{ #category : 'accessing' }
MCPStructureImageContent >> mimeType: aString [

	mimeType := aString
]
