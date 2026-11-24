"
Draws a MCPOcelFlowGraph on a Roassal canvas: a box per tool, from the left in the order the calls went, and an arrow per directly-follows edge, thicker the more cases it has. A tool that follows itself shows how many times in its box rather than as an arrow, and a tool with failed calls has a red border. Hovering a box or an arrow says its numbers.
"
Class {
	#name : 'MCPCallGraphDrawing',
	#superclass : 'Object',
	#instVars : [
		'flowGraph',
		'nodes'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'drawing' }
MCPCallGraphDrawing class >> drawFlowGraph: aFlowGraph on: aCanvas [
	"Replaces what aCanvas shows with the graph."

	aCanvas shapes copy do: [ :shape | shape remove ].
	^ self new
		  flowGraph: aFlowGraph;
		  drawOn: aCanvas;
		  yourself
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
MCPCallGraphDrawing >> drawEdgesOn: aCanvas [

	| arrows |
	arrows := flowGraph edges reject: [ :edge | edge isSelfLoop ].
	arrows isEmpty ifTrue: [ ^ self ].
	RSLineBuilder arrowedLine
		canvas: aCanvas;
		withBorderAttachPoint;
		color: (Color gray alpha: 0.8);
		shapes: nodes;
		useAssociations: (arrows collect: [ :edge | edge source -> edge target ] as: Array).
	aCanvas edges do: [ :line |
			| edge |
			edge := flowGraph edgeFrom: line model key to: line model value.
			line
				width: 1 + (edge count log: 2);
				popupText: [ :each | self describeEdge: edge ] ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> drawOn: aCanvas [

	nodes := flowGraph activitiesByFirstCall collect: [ :activity | self nodeFor: activity ].
	aCanvas addAll: nodes.
	self drawEdgesOn: aCanvas.
	self layOutNodes
]

{ #category : 'accessing' }
MCPCallGraphDrawing >> flowGraph: aFlowGraph [

	flowGraph := aFlowGraph
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
	"A column per layer, from the left, its boxes one under the other in the order of their first call, centered on the middle."

	| layers columnWidth rowHeight |
	layers := flowGraph layers.
	columnWidth := (nodes inject: 0 into: [ :widest :node | widest max: node width ]) + 90.
	rowHeight := 60.
	(nodes groupedBy: [ :node | layers at: node model ]) keysAndValuesDo: [ :layer :column |
		column withIndexDo: [ :node :index | node position: layer * columnWidth @ (index - 1 - (column size - 1 / 2) * rowHeight) ] ]
]

{ #category : 'drawing' }
MCPCallGraphDrawing >> nodeFor: anActivity [

	| label box errors |
	errors := flowGraph errorCountOf: anActivity.
	label := RSLabel new
		         text: (self labelOf: anActivity);
		         yourself.
	box := RSBox new
		       extent: label textWidth + 20 @ 28;
		       color: Color white;
		       border: (RSBorder new
				        color: (errors > 0
						         ifTrue: [ Color red ]
						         ifFalse: [ Color gray ]);
				        width: (errors > 0
						         ifTrue: [ 2 ]
						         ifFalse: [ 1 ]);
				        yourself);
		       cornerRadius: 6;
		       yourself.
	^ RSComposite new
		  model: anActivity;
		  shapes: {
				  box.
				  label };
		  popupText: [ :activity | self describe: activity ];
		  yourself
]
