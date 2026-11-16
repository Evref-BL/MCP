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
MCPUserInterfaceToolTest >> readScreenDataFor: aMorph depth: anInteger [
	"What screen_read answers about aMorph, read anInteger levels deep."

	^ (MCPToolReadScreen new resultForReadOf: aMorph target: 'world' depth: anInteger) structuredContent at: #data
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

	| data parent tree |
	parent := self morphOfExtent: 100 @ 50.
	parent addMorph: (self morphOfExtent: 10 @ 10).
	parent addMorph: (self morphOfExtent: 20 @ 20).
	data := self readScreenDataFor: parent depth: 2.
	tree := data at: #tree.
	self assert: (tree at: #class) equals: 'Morph'.
	self assert: (tree at: #bounds) equals: '0,0 100x50'.
	self assert: (tree at: #children) size equals: 2.
	self assert: (data at: #nodes) equals: 3
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenReadNamesAPlainWindow [

	| data |
	data := self readScreenDataFor: (SystemWindow labelled: 'Plain Window') depth: 0.
	self assert: ((data at: #tree) at: #title) equals: 'Plain Window'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenReadStopsAtTheRequestedDepth [

	| data parent |
	parent := self morphOfExtent: 100 @ 50.
	parent addMorph: (self morphOfExtent: 10 @ 10).
	data := self readScreenDataFor: parent depth: 0.
	self deny: ((data at: #tree) includesKey: #children).
	self assert: (data at: #nodes) equals: 1
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenshotNamesTheWindowItCaptured [

	| result |
	result := MCPToolCaptureScreen new resultForCaptureOf: (self morphOfExtent: 40 @ 30) target: 'Playground'.
	self assert: ((result structuredContent at: #data) at: #target) equals: 'Playground'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testWindowTitleIsTheLabelOfAPlainWindow [
	"A plain SystemWindow answers no #title, so the tools read the label every window carries."

	self assert: (MCPToolReadScreen new titleOf: (SystemWindow labelled: 'Plain Window')) equals: 'Plain Window'
]
