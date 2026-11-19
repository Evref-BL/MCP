"
MCP tool that answers what is on screen as a tree of nodes.

It is read-only, and it is the cheap counterpart of screen_capture: text a caller can search and assert on, for the price of a few hundred tokens rather than an image.
"
Class {
	#name : 'MCPToolReadScreen',
	#superclass : 'MCPTool',
	#traits : 'TMCPUserInterfaceTool',
	#classTraits : 'TMCPUserInterfaceTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolReadScreen class >> groupName [

	^ self uiGroupName
]

{ #category : 'metadata' }
MCPToolReadScreen class >> toolName [

	^ 'screen_read'
]

{ #category : 'metadata' }
MCPToolReadScreen >> additionalKeywords [

	^ #( 'ui' 'screen' 'window' 'morph' 'spec' 'presenter' )
]

{ #category : 'metadata' }
MCPToolReadScreen >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - reading' }
MCPToolReadScreen >> boundsTextFor: aMorph [

	| bounds |
	bounds := aMorph bounds.
	^ String streamContents: [ :stream |
			  stream
				  print: bounds left asInteger;
				  nextPut: $,;
				  print: bounds top asInteger;
				  space;
				  print: bounds width asInteger;
				  nextPut: $x;
				  print: bounds height asInteger ]
]

{ #category : 'metadata' }
MCPToolReadScreen >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  self windowSchemaProperty.
				  ((self schemaPropertyNamed: 'depth' type: 'integer' description: 'How deep to walk what the target contains.')
					   default: self defaultDepth;
					   minimum: 0;
					   maximum: self maximumDepth;
					   yourself) }
		  required: #(  )
]

{ #category : 'private - reading' }
MCPToolReadScreen >> childNodesOf: aMorph depth: remaining [

	^ (self presenterOf: aMorph)
		  ifNil: [ aMorph submorphs collect: [ :each | self nodeFor: each depth: remaining ] as: Array ]
		  ifNotNil: [ :presenter | { (self presenterNodeFor: presenter depth: remaining) } ]
]

{ #category : 'metadata' }
MCPToolReadScreen >> defaultDepth [
	"Deep enough to reach the presenters inside a window without walking every widget in it."

	^ 3
]

{ #category : 'metadata' }
MCPToolReadScreen >> description [

	^ 'Answer what is on screen as a tree: the open windows, or one window named by its title with the Spec presenters or morphs inside it. Text a caller can search and assert on, for a fraction of what a screenshot costs.'
]

{ #category : 'private - results' }
MCPToolReadScreen >> entryNameKeys [
	"A node is the morph or presenter of its class."

	^ #( class )
]

{ #category : 'executing' }
MCPToolReadScreen >> executeWithRequest: request [

	^ self executeRequest: request do: [
			  | window |
			  window := request stringArgumentNamed: 'window'.
			  self
				  resultForReadOf: (self targetMorphNamed: window)
				  target: (window ifNil: [ 'world' ])
				  depth: (request integerArgumentNamed: 'depth') ]
]

{ #category : 'private - results' }
MCPToolReadScreen >> keyOrder [
	"What a node is, then what it is called, then where it sits. Children come last, as the only part that is not one line."

	^ #( class title bounds visible )
]

{ #category : 'executing' }
MCPToolReadScreen >> keysStatedInSummary [
	"The summary names the target and counts the nodes, so repeating either says it twice."

	^ #( target nodes )
]

{ #category : 'metadata' }
MCPToolReadScreen >> maximumDepth [

	^ 10
]

{ #category : 'private - reading' }
MCPToolReadScreen >> nodeCountIn: aNode [

	^ 1 + ((aNode at: #children ifAbsent: [ #(  ) ]) inject: 0 into: [ :sum :each | sum + (self nodeCountIn: each) ])
]

{ #category : 'private - reading' }
MCPToolReadScreen >> nodeFor: aMorph depth: remaining [
	"What a morph is and what it holds. A window showing a Spec presenter is described by its presenters, because those carry the names a reader recognises."

	| node children |
	node := Dictionary new.
	node at: #class put: aMorph class name asString.
	(aMorph isKindOf: SystemWindow) ifTrue: [ node at: #title put: (self titleOf: aMorph) ].
	node at: #bounds put: (self boundsTextFor: aMorph).
	aMorph visible ifFalse: [ node at: #visible put: false ].
	remaining isZero ifFalse: [
			children := self childNodesOf: aMorph depth: remaining - 1.
			children ifNotEmpty: [ node at: #children put: children ] ].
	^ node
]

{ #category : 'private - reading' }
MCPToolReadScreen >> presenterNodeFor: aPresenter depth: remaining [

	| node children |
	node := Dictionary new.
	node at: #class put: aPresenter class name asString.
	remaining isZero ifFalse: [
			children := aPresenter presenters collect: [ :each | self presenterNodeFor: each depth: remaining - 1 ] as: Array.
			children ifNotEmpty: [ node at: #children put: children ] ].
	^ node
]

{ #category : 'private - reading' }
MCPToolReadScreen >> presenterOf: aMorph [
	"The Spec presenter a morph shows, when it shows one. A morph showing none answers nil."

	^ aMorph presenter ifNotNil: [ :windowPresenter | windowPresenter presenter ]
]

{ #category : 'private - results' }
MCPToolReadScreen >> resultForReadOf: aMorph target: aString depth: anInteger [
	"A morph and what it contains, as a tree of nodes walked anInteger levels deep. Any morph can be read, so a test needs no window open."

	| nodeCount tree |
	tree := self nodeFor: aMorph depth: anInteger.
	nodeCount := self nodeCountIn: tree.
	^ self successResultText: (self successSummaryForTarget: aString nodeCount: nodeCount) data: {
			  (#target -> aString).
			  (#nodes -> nodeCount).
			  (#tree -> tree) } asDictionary
]

{ #category : 'private - results' }
MCPToolReadScreen >> successSummaryForTarget: aString nodeCount: anInteger [

	^ String streamContents: [ :stream | stream << 'Read ' << aString << ', ' << (self textForCount: anInteger noun: 'node') << '.' ]
]

{ #category : 'metadata' }
MCPToolReadScreen >> title [

	^ 'Read Screen'
]
