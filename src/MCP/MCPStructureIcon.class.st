"
MCP protocol structure for server and tool icons.

It stores icon source, MIME type, size information, and optional theme metadata.
"
Class {
	#name : 'MCPStructureIcon',
	#superclass : 'Object',
	#instVars : [
		'src',
		'mimeType',
		'sizes',
		'theme'
	],
	#classInstVars : [
		'iconCache',
		'toolIconCache'
	],
	#category : 'MCP-Icons',
	#package : 'MCP',
	#tag : 'Icons'
}

{ #category : 'instance creation' }
MCPStructureIcon class >> compositeFormBaseIconNamed: aBaseIconSymbol leftBadgeIconNamed: aLeftBadgeIconSymbol rightBadgeIconNamed: aRightBadgeIconSymbol [
	"The left badge, which may be nil, sits at the bottom left and the right one at the bottom right."

	| badgeSize baseForm canvas composite rightBadgeForm |
	baseForm := self highScaleFormNamed: aBaseIconSymbol.
	badgeSize := baseForm width // 2 @ (baseForm height // 2).
	composite := Form extent: baseForm extent depth: 32.
	canvas := composite getCanvas.
	canvas translucentImage: baseForm at: 0 @ 0.
	aLeftBadgeIconSymbol ifNotNil: [
			| leftBadgeForm |
			leftBadgeForm := (self highScaleFormNamed: aLeftBadgeIconSymbol) scaledToSize: badgeSize.
			canvas translucentImage: leftBadgeForm at: 0 @ (composite height - leftBadgeForm height) ].
	rightBadgeForm := (self highScaleFormNamed: aRightBadgeIconSymbol) scaledToSize: badgeSize.
	canvas translucentImage: rightBadgeForm at: composite extent - rightBadgeForm extent.
	^ composite
]

{ #category : 'instance creation' }
MCPStructureIcon class >> highScaleFormNamed: anIconSymbol [

	anIconSymbol = #pharoHalfScale ifTrue: [
			| pharoForm |
			pharoForm := self highScaleFormNamed: #pharo.
			^ pharoForm scaledToSize: pharoForm width // 2 @ (pharoForm height // 2) ].
	anIconSymbol = #referencesUpsideDown ifTrue: [ ^ (self highScaleFormNamed: #references) rotateBy: 180 ].
	^ self highScaleIconNamed: anIconSymbol
]

{ #category : 'cache' }
MCPStructureIcon class >> iconCache [

	^ iconCache ifNil: [ iconCache := Dictionary new ]
]

{ #category : 'instance creation' }
MCPStructureIcon class >> iconForForm: aForm [

	^ self new
		  src: (self pngDataUriForForm: aForm);
		  mimeType: 'image/png';
		  sizes: { (self pngSizeStringForForm: aForm) };
		  yourself
]

{ #category : 'cache' }
MCPStructureIcon class >> iconForSpec: anIconSpec [

	^ self iconCache at: anIconSpec cacheKey ifAbsentPut: [ anIconSpec renderUsing: self ]
]

{ #category : 'cache' }
MCPStructureIcon class >> iconsForToolClass: aToolClass [

	^ self toolIconCache at: aToolClass ifAbsentPut: [ { (self iconForSpec: aToolClass toolIconSpec) } ]
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngDataUriForForm: aForm [

	^ 'data:image/png;base64,' , (MCPStructureImageContent pngFromForm: aForm) data
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngIconNamed: anIconSymbol [

	^ self iconForSpec: (MCPToolIconSpec named: anIconSymbol)
]

{ #category : 'instance creation' }
MCPStructureIcon class >> pngSizeStringForForm: aForm [

	^ String streamContents: [ :stream | stream << aForm width asString << 'x' << aForm height asString ]
]

{ #category : 'cache' }
MCPStructureIcon class >> resetCaches [

	<script>
	iconCache := nil.
	toolIconCache := nil
]

{ #category : 'cache' }
MCPStructureIcon class >> toolIconCache [

	^ toolIconCache ifNil: [ toolIconCache := IdentityDictionary new ]
]

{ #category : 'accessing' }
MCPStructureIcon >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self src ifNotNil: [ dic at: #src put: self src asJRPCJSON ].
	self mimeType ifNotNil: [ dic at: #mimeType put: self mimeType asJRPCJSON ].
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
