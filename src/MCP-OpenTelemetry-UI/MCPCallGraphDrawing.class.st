"
Draws a MCPOcelFlowGraph on a Roassal canvas: a box per tool, from the left in the order the calls went, and an arrow per directly-follows edge, thicker the more cases it has. A tool that follows itself shows how many times in its box rather than as an arrow, and a tool with failed calls has a red border. It is interactive: boxes can be dragged, hovering a box or an arrow lights it with what it is connected to and dims the rest, and hovering says its numbers; clicking a box or an arrow selects it and tells whoever listens (onActivityClicked:, onEdgeClicked:), which may select it in its own way, and selectActivity: and selectEdgeFrom:to: select from the outside without telling. Positions the user dragged boxes to can be handed to the next drawing (initialPositions:) so that a redraw does not undo them.
"
Class {
	#name : 'MCPCallGraphDrawing',
	#superclass : 'Object',
	#instVars : [
		'flowGraph',
		'nodes',
		'canvas',
		'lines',
		'hoveredActivity',
		'hoveredEdge',
		'selectedActivity',
		'selectedEdge',
		'initialPositions',
		'onActivityClicked',
		'onEdgeClicked'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'drawing' }
MCPCallGraphDrawing class >> drawFlowGraph: aFlowGraph on: aCanvas [
	"Replaces what aCanvas shows with the graph."

	^ self new
		  flowGraph: aFlowGraph;
		  drawOn: aCanvas;
		  yourself
]

{ #category : 'interaction' }
MCPCallGraphDrawing >> addInteractions [

	nodes do: [ :node |
			| activity |
			activity := node model.
			node @ RSDraggable.
			node
				when: RSMouseEnter do: [ :event |
						hoveredActivity := activity.
						self applyStyles ]
				for: self;
				when: RSMouseLeave do: [ :event |
						hoveredActivity := nil.
						self applyStyles ]
				for: self;
				when: RSMouseClick do: [ :event | self clickActivity: activity ] for: self ].
	lines keysAndValuesDo: [ :key :line |
			line
				when: RSMouseEnter do: [ :event |
						hoveredEdge := key.
						self applyStyles ]
				for: self;
				when: RSMouseLeave do: [ :event |
						hoveredEdge := nil.
						self applyStyles ]
				for: self;
				when: RSMouseClick do: [ :event | self clickEdge: key ] for: self ]
]

{ #category : 'styling' }
MCPCallGraphDrawing >> applyStyles [
	"What is hovered, else what is selected, is lit with what it is connected to, and the rest is dimmed: a tool lights its arrows and the tools at their ends, an arrow its two tools."

	| focusActivity focusEdge anyFocus |
	focusActivity := hoveredActivity ifNil: [ hoveredEdge ifNil: [ selectedActivity ] ifNotNil: [ nil ] ].
	focusEdge := hoveredEdge ifNil: [ hoveredActivity ifNil: [ selectedEdge ] ifNotNil: [ nil ] ].
	anyFocus := focusActivity isNotNil or: [ focusEdge isNotNil ].
	nodes do: [ :node |
			| activity lit |
			activity := node model.
			lit := anyFocus not or: [ self isActivity: activity litBy: focusActivity edge: focusEdge ].
			node shapes first border: (self borderOf: activity lit: lit focused: activity = focusActivity) ].
	lines keysAndValuesDo: [ :key :line |
			| lit |
			lit := self isEdge: key litBy: focusActivity edge: focusEdge.
			line color: (lit
					 ifTrue: [ self litColor ]
					 ifFalse: [
							 Color gray alpha: (anyFocus
									  ifTrue: [ 0.25 ]
									  ifFalse: [ 0.8 ]) ]) ].
	canvas signalUpdate
]

{ #category : 'styling' }
MCPCallGraphDrawing >> borderOf: anActivity lit: lit focused: focused [
	"Red for a tool with failed calls, else blue when lit and gray when not; thicker for the focused one, and faded when something else is."

	| failed color |
	failed := (flowGraph errorCountOf: anActivity) > 0.
	color := failed
		         ifTrue: [ Color red ]
		         ifFalse: [
				         lit
					         ifTrue: [ self litColor ]
					         ifFalse: [ Color gray ] ].
	^ RSBorder new
		  color: (lit
				   ifTrue: [ color ]
				   ifFalse: [ color alpha: 0.3 ]);
		  width: (focused
				   ifTrue: [ 3 ]
				   ifFalse: [
						   failed
							   ifTrue: [ 2 ]
							   ifFalse: [ 1 ] ]);
		  yourself
]

{ #category : 'interaction' }
MCPCallGraphDrawing >> clickActivity: anActivity [
	"Selects the tool, or drops the selection when it is the one selected, and tells the listener."

	selectedEdge := nil.
	selectedActivity := selectedActivity = anActivity
		                    ifTrue: [ nil ]
		                    ifFalse: [ anActivity ].
	self applyStyles.
	onActivityClicked ifNotNil: [ :block | block value: selectedActivity ]
]

{ #category : 'interaction' }
MCPCallGraphDrawing >> clickEdge: anEdgeKey [
	"Selects the arrow, or drops the selection when it is the one selected, and tells the listener with the edge."

	selectedActivity := nil.
	selectedEdge := selectedEdge = anEdgeKey
		                ifTrue: [ nil ]
		                ifFalse: [ anEdgeKey ].
	self applyStyles.
	onEdgeClicked ifNotNil: [ :block | block value: (selectedEdge ifNotNil: [ :key | flowGraph edgeFrom: key key to: key value ]) ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> describe: anActivity [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: anActivity;
				  cr;
				  print: (flowGraph callCountOf: anActivity);
				  nextPutAll: ' calls, ';
				  print: (flowGraph errorCountOf: anActivity);
				  nextPutAll: ' failed, ';
				  nextPutAll: ((flowGraph meanDurationMillisecondsOf: anActivity) asFloat printShowingDecimalPlaces: 1);
				  nextPutAll: ' ms on average' ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> describeEdge: anEdge [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: anEdge source;
				  nextPutAll: ' directly followed by ';
				  nextPutAll: anEdge target;
				  cr;
				  print: anEdge count;
				  nextPutAll: ' times, by ';
				  print: anEdge objectCount;
				  nextPutAll: ' objects, ';
				  nextPutAll: (anEdge meanGapMilliseconds asFloat printShowingDecimalPlaces: 1);
				  nextPutAll: ' ms between starts on average' ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> drawEdges [

	| arrows |
	lines := Dictionary new.
	arrows := flowGraph edges reject: [ :edge | edge isSelfLoop ].
	arrows isEmpty ifTrue: [ ^ self ].
	RSLineBuilder arrowedLine
		canvas: canvas;
		withBorderAttachPoint;
		shapes: nodes;
		useAssociations: (arrows collect: [ :edge | edge source -> edge target ] as: Array).
	canvas edges do: [ :line |
			| edge |
			edge := flowGraph edgeFrom: line model key to: line model value.
			lines at: line model put: line.
			line
				width: 1 + (edge count log: 2);
				popupText: [ :each | self describeEdge: edge ] ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> drawOn: aCanvas [

	canvas := aCanvas.
	canvas shapes copy do: [ :shape | shape remove ].
	nodes := flowGraph activitiesByFirstCall collect: [ :activity | self nodeFor: activity ].
	canvas addAll: nodes.
	self drawEdges.
	self layOutNodes.
	self addInteractions.
	self applyStyles
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> flowGraph: aFlowGraph [

	flowGraph := aFlowGraph
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> iconFormFor: anActivity [
	"The icon the dashboard shows for the tool of this name."

	^ ((MCPToolIconSpec forToolName: anActivity) formUsing: MCPStructureIcon) scaledIntoFormOfSize: self iconSize
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> iconSize [

	^ 16
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> initialPositions: aDictionary [
	"Where the boxes of these tools were, as tool -> point, which a box is put back to."

	initialPositions := aDictionary
]

{ #category : 'styling' }
MCPCallGraphDrawing >> isActivity: anActivity litBy: focusActivity edge: focusEdge [

	focusActivity ifNotNil: [
			anActivity = focusActivity ifTrue: [ ^ true ].
			^ lines keys anySatisfy: [ :key |
				  (key key = focusActivity and: [ key value = anActivity ]) or: [ key value = focusActivity and: [ key key = anActivity ] ] ] ].
	focusEdge ifNotNil: [ ^ anActivity = focusEdge key or: [ anActivity = focusEdge value ] ].
	^ false
]

{ #category : 'styling' }
MCPCallGraphDrawing >> isEdge: anEdgeKey litBy: focusActivity edge: focusEdge [

	focusActivity ifNotNil: [ ^ anEdgeKey key = focusActivity or: [ anEdgeKey value = focusActivity ] ].
	^ focusEdge = anEdgeKey
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> labelOf: anActivity [
	"The tool, and how many times it follows itself when it does."

	^ (flowGraph edgeFrom: anActivity to: anActivity) ifNil: [ anActivity ] ifNotNil: [ :loop |
			  String streamContents: [ :stream |
					  stream
						  nextPutAll: anActivity;
						  nextPutAll: '  (again x';
						  print: loop count;
						  nextPut: $) ] ]
]

{ #category : 'layout' }
MCPCallGraphDrawing >> layOutNodes [
	"A column per layer, from the left, its boxes one under the other in the order of their first call, centered on the middle; but a box the user had dragged somewhere stays there."

	| layers columnWidth rowHeight |
	layers := flowGraph layers.
	columnWidth := (nodes inject: 0 into: [ :widest :node | widest max: node width ]) + 90.
	rowHeight := 60.
	(nodes groupedBy: [ :node | layers at: node model ]) keysAndValuesDo: [ :layer :column |
		column withIndexDo: [ :node :index | node position: layer * columnWidth @ (index - 1 - (column size - 1 / 2) * rowHeight) ] ].
	initialPositions ifNotNil: [
		nodes do: [ :node | initialPositions at: node model ifPresent: [ :position | node position: position ] ] ]
]

{ #category : 'styling' }
MCPCallGraphDrawing >> litColor [

	^ Color fromHexString: '2B6FDB'
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> nodeFor: anActivity [
	"A box with the icon of the tool, as in the dashboard, then its name."

	| label box icon gap padding width |
	gap := 6.
	padding := 10.
	label := RSLabel new
		         text: (self labelOf: anActivity);
		         yourself.
	icon := RSBitmap new
		        form: (self iconFormFor: anActivity);
		        yourself.
	width := padding + self iconSize + gap + label textWidth + padding.
	box := RSBox new
		       extent: width @ 28;
		       color: Color white;
		       cornerRadius: 6;
		       yourself.
	icon translateTo: padding - (width / 2) + (self iconSize / 2) @ 0.
	label translateTo: padding + self iconSize + gap - (width / 2) + (label textWidth / 2) @ 0.
	^ RSComposite new
		  model: anActivity;
		  shapes: {
				  box.
				  icon.
				  label };
		  popupText: [ :activity | self describe: activity ];
		  yourself
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> nodePositions [
	"Where the box of each tool is now, which a drag may have changed."

	| positions |
	positions := Dictionary new.
	nodes ifNotNil: [ nodes do: [ :node | positions at: node model put: node position ] ].
	^ positions
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> onActivityClicked: aBlock [
	"Evaluated with the tool whose box was clicked."

	onActivityClicked := aBlock
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> onEdgeClicked: aBlock [
	"Evaluated with the edge whose arrow was clicked."

	onEdgeClicked := aBlock
]

{ #category : 'interaction' }
MCPCallGraphDrawing >> selectActivity: anActivity [
	"Selects the tool from the outside, nil to drop the selection, without telling the listener."

	selectedEdge := nil.
	selectedActivity := anActivity.
	self applyStyles
]

{ #category : 'interaction' }
MCPCallGraphDrawing >> selectEdge: anEdge [
	"Selects the arrow of an edge from the outside, nil to drop the selection, without telling the listener. A tool that follows itself has no arrow: its box is selected instead."

	selectedActivity := nil.
	selectedEdge := nil.
	anEdge ifNotNil: [
			anEdge isSelfLoop
				ifTrue: [ selectedActivity := anEdge source ]
				ifFalse: [ selectedEdge := anEdge source -> anEdge target ] ].
	self applyStyles
]
