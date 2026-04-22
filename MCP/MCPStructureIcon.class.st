Class {
	#name : 'MCPStructureIcon',
	#superclass : 'Object',
	#instVars : [
		'src',
		'mimeType',
		'sizes',
		'theme'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPStructureIcon class >> compositeBaseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	^ self iconForForm: (self
			   compositeFormBaseIconNamed: aBaseIconSymbol
			   badgeIconNamed: aBadgeIconSymbol)
]

{ #category : 'instance creation' }
MCPStructureIcon class >> compositeFormBaseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	| baseForm badgeForm badgeSize canvas composite |
	baseForm := self highScaleFormNamed: aBaseIconSymbol.
	badgeSize := baseForm width // 2 @ (baseForm height // 2).
	badgeForm := (self highScaleFormNamed: aBadgeIconSymbol)
		             scaledToSize: badgeSize.
	composite := Form extent: baseForm extent depth: 32.
	canvas := composite getCanvas.
	canvas translucentImage: baseForm at: 0 @ 0.
	canvas
		translucentImage: badgeForm
		at: composite extent - badgeForm extent.
	^ composite
]

{ #category : 'instance creation' }
MCPStructureIcon class >> highScaleFormNamed: anIconSymbol [

	| scaledIcons |
	scaledIcons := Smalltalk ui icons iconsPerScale
		               at: 2.0
		               ifAbsent: [
		               self error: 'Missing precomputed scale 2.0 icons.' ].
	^ scaledIcons
		  at: anIconSymbol
		  ifAbsent: [
		  self error: 'Missing UI icon named ' , anIconSymbol asString ]
]

{ #category : 'instance creation' }
MCPStructureIcon class >> horizontallyFlippedPngIconNamed: anIconSymbol [

	^ self iconForForm:
		  (self highScaleFormNamed: anIconSymbol) deepCopy flipHorizontally
]

{ #category : 'instance creation' }
MCPStructureIcon class >> iconForForm: aForm [

	^ self new
		  src: (self pngDataUriForForm: aForm);
		  mimeType: 'image/png';
		  sizes: { (self pngSizeStringForForm: aForm) };
		  yourself
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngDataUriForForm: aForm [

	| bytes |
	bytes := ByteArray streamContents: [ :stream |
		         PNGReadWriter putForm: aForm onStream: stream ].
	^ 'data:image/png;base64,' , bytes base64Encoded
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngIconNamed: anIconSymbol [

	^ self iconForForm: (self highScaleFormNamed: anIconSymbol)
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngSizeStringForForm: aForm [

	^ aForm width asString , 'x' , aForm height asString
]

{ #category : 'accessing' }
MCPStructureIcon >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self src ifNotNil: [ dic at: #src put: self src asJRPCJSON ].
	self mimeType ifNotNil: [
		dic at: #mimeType put: self mimeType asJRPCJSON ].
	self sizes ifNotNil: [ dic at: #sizes put: self sizes asJRPCJSON ].
	self theme ifNotNil: [ dic at: #theme put: self theme asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureIcon >> mimeType [

	^ mimeType
]

{ #category : 'accessing' }
MCPStructureIcon >> mimeType: anObject [

	mimeType := anObject
]

{ #category : 'accessing' }
MCPStructureIcon >> sizes [

	^ sizes
]

{ #category : 'accessing' }
MCPStructureIcon >> sizes: anObject [

	sizes := anObject
]

{ #category : 'accessing' }
MCPStructureIcon >> src [

	^ src
]

{ #category : 'accessing' }
MCPStructureIcon >> src: anObject [

	src := anObject
]

{ #category : 'accessing' }
MCPStructureIcon >> theme [

	^ theme
]

{ #category : 'accessing' }
MCPStructureIcon >> theme: anObject [

	theme := anObject
]
