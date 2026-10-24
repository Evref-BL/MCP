"
Command that describes a morph and what it contains as a tree of nodes.

A window showing a Spec presenter is described by its presenters, because those carry the names a reader recognises; anything else is described by its submorphs.
"
Class {
	#name : 'MCPReadScreenCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'morph'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReadScreenCommand class >> tool: aTool request: aRequest morph: aMorph [

	^ self new initializeTool: aTool request: aRequest morph: aMorph
]

{ #category : 'private' }
MCPReadScreenCommand >> boundsTextFor: aMorph [

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

{ #category : 'private' }
MCPReadScreenCommand >> childNodesOf: aMorph depth: remaining [

	^ (self presenterOf: aMorph)
		  ifNil: [ (aMorph submorphs collect: [ :each | self nodeFor: each depth: remaining ]) asArray ]
		  ifNotNil: [ :presenter | { (self presenterNodeFor: presenter depth: remaining) } ]
]

{ #category : 'executing' }
MCPReadScreenCommand >> execute [

	| tree |
	tree := self nodeFor: morph depth: request depth.
	^ MCPReadScreenResult target: request targetLabel nodeCount: (self nodeCountIn: tree) tree: tree
]

{ #category : 'private' }
MCPReadScreenCommand >> initializeTool: aTool request: aRequest morph: aMorph [

	super initializeTool: aTool request: aRequest.
	morph := aMorph
]

{ #category : 'private' }
MCPReadScreenCommand >> nodeCountIn: aNode [

	^ 1 + ((aNode at: #children ifAbsent: [ #(  ) ]) inject: 0 into: [ :sum :each | sum + (self nodeCountIn: each) ])
]

{ #category : 'private' }
MCPReadScreenCommand >> nodeFor: aMorph depth: remaining [
	"What a morph is and what it holds. A window showing a Spec presenter is described by its presenters, because those carry the names a reader recognises."

	| node children |
	node := Dictionary new.
	node at: #class put: aMorph class name asString.
	(aMorph isKindOf: SystemWindow) ifTrue: [ node at: #title put: aMorph title asString ].
	node at: #bounds put: (self boundsTextFor: aMorph).
	aMorph visible ifFalse: [ node at: #visible put: false ].
	remaining isZero ifFalse: [
			children := self childNodesOf: aMorph depth: remaining - 1.
			children ifNotEmpty: [ node at: #children put: children ] ].
	^ node
]

{ #category : 'private' }
MCPReadScreenCommand >> presenterNodeFor: aPresenter depth: remaining [

	| node children |
	node := Dictionary new.
	node at: #class put: aPresenter class name asString.
	remaining isZero ifFalse: [
			children := (aPresenter presenters collect: [ :each | self presenterNodeFor: each depth: remaining - 1 ]) asArray.
			children ifNotEmpty: [ node at: #children put: children ] ].
	^ node
]

{ #category : 'private' }
MCPReadScreenCommand >> presenterOf: aMorph [
	"The Spec presenter a morph shows, when it shows one. A morph showing none answers nil."

	^ aMorph presenter ifNotNil: [ :windowPresenter | windowPresenter presenter ]
]
