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
		'onEdgeClicked',
		'layoutName'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'layout' }
MCPCallGraphDrawing class >> defaultLayoutName [

	^ self layoutNames first
]

{ #category : 'drawing' }
MCPCallGraphDrawing class >> drawFlowGraph: aFlowGraph on: aCanvas [
	"Replaces what aCanvas shows with the graph."

	^ self new
		  flowGraph: aFlowGraph;
		  drawOn: aCanvas;
		  yourself
]

{ #category : 'layout' }
MCPCallGraphDrawing class >> layoutNames [
	"The layouts a graph can be drawn with, the default first."

	^ #( 'Force' 'Layers' 'Circle' 'Grid' )
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

{ #category : 'layout' }
MCPCallGraphDrawing >> centerNodes [
	"Moves all the boxes together so that their middle is the origin."

	| sum |
	nodes ifEmpty: [ ^ self ].
	sum := nodes inject: 0 @ 0 into: [ :total :node | total + node position ].
	nodes do: [ :node | node position: node position - (sum / nodes size) ]
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
				width: (self widthOfCount: edge count);
				popupText: [ :each | self describeEdge: edge ] ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> drawLegend [
	"A fixed key at the top right of the canvas: how thick an arrow is for how many cases."

	| legend |
	legend := RSLegend new.
	legend container: canvas.
	legend title: 'Directly follows'.
	{
		1.
		10.
		25.
		self maxCountForWidth } do: [ :count |
			legend
				text: (count = self maxCountForWidth
						 ifTrue: [ count printString , '+ cases' ]
						 ifFalse: [
								 count printString , (count = 1
									  ifTrue: [ ' case' ]
									  ifFalse: [ ' cases' ]) ])
				withShape: (RSBox new
						 width: 28;
						 height: (self widthOfCount: count);
						 color: Color gray;
						 yourself) ].
	legend legendDo: [ :shape |
			shape
				withBorder;
				padding: 8 ].
	legend location
		right;
		top.
	legend build
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
	self drawLegend.
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
MCPCallGraphDrawing >> layOutByForce [
	"The arrows pull the boxes they join together, the boxes push each other apart, and everything is drawn to the middle: a tool followed by many is near them, one on its own is not far off. The same graph always gives the same drawing."

	| spread |
	nodes size < 2 ifTrue: [ ^ nodes do: [ :node | node position: 0 @ 0 ] ].
	spread := (nodes inject: 0 into: [ :widest :node | widest max: node width ]) + 60.
	RSForceBasedLayout new
		length: spread;
		charge: spread negated * 3;
		gravity: 0.1;
		on: nodes.
	self separateOverlappingNodes.
	self centerNodes
]

{ #category : 'layout' }
MCPCallGraphDrawing >> layOutInCircle [
	"The boxes on a circle, in the order of their first call."

	nodes size < 2 ifTrue: [ ^ nodes do: [ :node | node position: 0 @ 0 ] ].
	RSCircleLayout new
		initialRadius: (nodes size * 70 max: 150);
		on: nodes.
	self centerNodes
]

{ #category : 'layout' }
MCPCallGraphDrawing >> layOutInGrid [
	"Rows of boxes, in the order of their first call."

	nodes size < 2 ifTrue: [ ^ nodes do: [ :node | node position: 0 @ 0 ] ].
	RSGridLayout new
		gapSize: 40;
		on: nodes.
	self centerNodes
]

{ #category : 'layout' }
MCPCallGraphDrawing >> layOutInLayers [
	"A column per layer, from the left, its boxes one under the other in the order of their first call, centered on the middle."

	| layers columnWidth rowHeight |
	layers := flowGraph layers.
	columnWidth := (nodes inject: 0 into: [ :widest :node | widest max: node width ]) + 90.
	rowHeight := 60.
	(nodes groupedBy: [ :node | layers at: node model ]) keysAndValuesDo: [ :layer :column |
		column withIndexDo: [ :node :index | node position: layer * columnWidth @ (index - 1 - (column size - 1 / 2) * rowHeight) ] ]
]

{ #category : 'layout' }
MCPCallGraphDrawing >> layOutNodes [
	"The boxes put as the layout picked says; but a box the user had dragged somewhere stays there."

	| name |
	name := layoutName ifNil: [ self class defaultLayoutName ].
	name = 'Layers' ifTrue: [ self layOutInLayers ].
	name = 'Force' ifTrue: [ self layOutByForce ].
	name = 'Circle' ifTrue: [ self layOutInCircle ].
	name = 'Grid' ifTrue: [ self layOutInGrid ].
	initialPositions ifNotNil: [
		nodes do: [ :node | initialPositions at: node model ifPresent: [ :position | node position: position ] ] ]
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> layoutName: aName [
	"One of the layoutNames of the class."

	layoutName := aName
]

{ #category : 'styling' }
MCPCallGraphDrawing >> litColor [

	^ Color fromHexString: '2B6FDB'
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> maxCountForWidth [
	"From this many cases on, an arrow is as thick as it gets."

	^ 50
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

{ #category : 'layout' }
MCPCallGraphDrawing >> separateOverlappingNodes [
	"Boxes that touch, or come within a few pixels of each other, are pushed apart along the axis where they overlap least, until none does or the passes are spent."

	| margin |
	margin := 10.
	50 timesRepeat: [
			| moved |
			moved := false.
			nodes doWithIndex: [ :a :i |
					(nodes allButFirst: i) do: [ :b |
							| ra rb overlapX overlapY |
							ra := a encompassingRectangle.
							rb := b encompassingRectangle.
							overlapX := (ra right min: rb right) - (ra left max: rb left) + margin.
							overlapY := (ra bottom min: rb bottom) - (ra top max: rb top) + margin.
							(overlapX > 0 and: [ overlapY > 0 ]) ifTrue: [
									| push |
									moved := true.
									push := overlapX < overlapY
										        ifTrue: [
												        overlapX / 2 * (a position x <= b position x
													         ifTrue: [ -1 ]
													         ifFalse: [ 1 ]) @ 0 ]
										        ifFalse: [
												        0 @ (overlapY / 2 * (a position y <= b position y
													          ifTrue: [ -1 ]
													          ifFalse: [ 1 ])) ].
									a position: a position + push.
									b position: b position - push ] ] ].
			moved ifFalse: [ ^ self ] ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> widthOfCount: aCount [
	"From 1 pixel for a single case, growing in step with the count, to 9 pixels at the maximum and above."

	^ 1 + (8 * ((aCount min: self maxCountForWidth) - 1) / (self maxCountForWidth - 1))
]

{ #category : 'layout' }
MCPCallGraphDrawing >> zoomToFitNodes [
	"The camera on the boxes, the legend being a corner of the view and not a part of the graph."

	| bounds |
	nodes ifEmpty: [ ^ self ].
	bounds := Rectangle merging: (nodes collect: [ :node | node encompassingRectangle ]).
	canvas camera zoomToFit: canvas extent rectangle: (bounds expandBy: 40)
]
