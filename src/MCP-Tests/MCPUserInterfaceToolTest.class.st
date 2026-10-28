"
Tests the tools that look at the running image: the screenshot capture and the screen reader, and the window resolution they share.
"
Class {
	#name : 'MCPUserInterfaceToolTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPUserInterfaceToolTest >> morphOfExtent: anExtent [

	^ Morph new
		  extent: anExtent;
		  yourself
]

{ #category : 'private' }
MCPUserInterfaceToolTest >> readScreenCommandFor: aMorph depth: anInteger [

	^ MCPReadScreenCommand
		  tool: MCPToolReadScreen new
		  request: (MCPReadScreenRequest new initializeWindow: nil depth: anInteger)
		  morph: aMorph
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testNamingAWindowThatIsNotOpenIsAnError [

	| error |
	error := nil.
	[ MCPToolReadScreen new targetMorphNamed: 'no such window' ]
		on: MCPCommandError
		do: [ :signal | error := signal ].
	self assert: error isNotNil.
	self assert: (error messageText includesSubstring: 'no such window').
	self deny: ((error structuredDetails at: #open) includes: 'no such window')
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenReadDescribesWhatAMorphHolds [

	| parent result tree |
	parent := self morphOfExtent: 100 @ 50.
	parent addMorph: (self morphOfExtent: 10 @ 10).
	parent addMorph: (self morphOfExtent: 20 @ 20).
	result := (self readScreenCommandFor: parent depth: 2) execute.
	tree := result tree.
	self assert: (tree at: #class) equals: 'Morph'.
	self assert: (tree at: #bounds) equals: '0,0 100x50'.
	self assert: (tree at: #children) size equals: 2.
	self assert: result nodeCount equals: 3
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenReadNamesAPlainWindow [

	| result |
	result := (self readScreenCommandFor: (SystemWindow labelled: 'Plain Window') depth: 0) execute.
	self assert: (result tree at: #title) equals: 'Plain Window'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenReadStopsAtTheRequestedDepth [

	| parent result |
	parent := self morphOfExtent: 100 @ 50.
	parent addMorph: (self morphOfExtent: 10 @ 10).
	result := (self readScreenCommandFor: parent depth: 0) execute.
	self deny: (result tree includesKey: #children).
	self assert: result nodeCount equals: 1
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenshotNamesTheWindowItCaptured [

	| result |
	result := (MCPScreenshotCommand
		           tool: MCPToolCaptureScreen new
		           request: (MCPScreenshotRequest new initializeWindow: 'Playground')
		           morph: (self morphOfExtent: 40 @ 30)) execute.
	self assert: result target equals: 'Playground'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testWindowTitleIsTheLabelOfAPlainWindow [
	"A plain SystemWindow answers no #title, so the tools read the label every window carries."

	self assert: (MCPToolReadScreen new titleOf: (SystemWindow labelled: 'Plain Window')) equals: 'Plain Window'
]
