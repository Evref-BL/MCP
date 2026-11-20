"
Tests the tools that look at the running image: the screenshot capture and the screen reader, and the window resolution they share.
"
Class {
	#name : 'MCPUserInterfaceToolTest',
	#superclass : 'MCPToolAPITestCase',
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
MCPUserInterfaceToolTest >> readScreenContentFor: aMorph depth: anInteger [
	"What screen_read answers about aMorph, read anInteger levels deep: its summary and its data."

	^ (MCPToolReadScreen new resultForReadOf: aMorph target: 'world' depth: anInteger) structuredContent
]

{ #category : 'private' }
MCPUserInterfaceToolTest >> readScreenDataFor: aMorph depth: anInteger [

	^ (self readScreenContentFor: aMorph depth: anInteger) at: #data
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testAMessageNotUnderstoodInAScreenToolSuggestsSelectors [
	"A slip in a screen tool's own code is answered as in any other tool, with the selectors the mistyped one resembles."

	| error tool |
	tool := MCPToolReadScreenMistyping new.
	error := (tool executeWithRequest: (tool requestFromToolCallArguments: Dictionary new)) structuredContent at: #error.
	self assert: ((error at: #suggestedSelectors) includes: 'addMorph:')
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testCaptureScreenHasAccurateNameAndSchemas [

	| inputPropertyNames tool |
	tool := MCPToolCaptureScreen new.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	self assert: tool name equals: 'screen_capture'.
	self assert: tool inputSchema required equals: #(  ).
	self assert: inputPropertyNames equals: #( 'window' )
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testCaptureScreenPackagesTheFormAsImageContent [

	| data imageContent imageJSON result |
	result := MCPToolCaptureScreen new
		          resultForCaptureOf: (Morph new
				           extent: 2 @ 3;
				           yourself)
		          window: nil.
	data := result structuredContent at: #data.
	imageContent := result content second.
	imageJSON := imageContent asJRPCJSON.
	self assert: (data at: #target) equals: 'world'.
	self assert: (data at: #width) equals: 2.
	self assert: (data at: #height) equals: 3.
	self assert: imageContent mimeType equals: 'image/png'.
	self assert: imageContent data isNotEmpty.
	self assert: (imageJSON at: #type) equals: 'image'.
	self assert: (imageJSON at: #mimeType) equals: 'image/png'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testNamingAWindowThatIsNotOpenIsAnError [

	| error |
	error := self capture: [ MCPToolReadScreen new targetMorphNamed: 'no such window' ].
	self assert: (error messageText includesSubstring: 'no such window').
	self deny: ((error structuredDetails at: #open) includes: 'no such window')
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testReadScreenHasAccurateNameAndSchemas [

	| depthProperty inputPropertyNames tool |
	tool := MCPToolReadScreen new.
	inputPropertyNames := tool inputSchema properties collect: [ :each | each name ].
	depthProperty := self inputPropertyNamed: 'depth' inTool: tool.
	self assert: tool name equals: 'screen_read'.
	self assert: tool inputSchema required equals: #(  ).
	self assert: inputPropertyNames equals: #( 'window' 'depth' ).
	self assert: (depthProperty extraProperties at: #default) equals: tool defaultDepth.
	self assert: (depthProperty extraProperties at: #maximum) equals: tool maximumDepth
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

	| content parent |
	parent := self morphOfExtent: 100 @ 50.
	parent addMorph: (self morphOfExtent: 10 @ 10).
	content := self readScreenContentFor: parent depth: 0.
	self deny: (((content at: #data) at: #tree) includesKey: #children).
	self assert: ((content at: #data) at: #nodes) equals: 1.
	self assert: (content at: #summary) equals: 'Read world, 1 node.'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testScreenshotNamesTheWindowItCaptured [

	| result |
	result := MCPToolCaptureScreen new resultForCaptureOf: (self morphOfExtent: 40 @ 30) window: 'Playground'.
	self assert: ((result structuredContent at: #data) at: #target) equals: 'Playground'
]

{ #category : 'tests' }
MCPUserInterfaceToolTest >> testWindowTitleIsTheLabelOfAPlainWindow [
	"A plain SystemWindow answers no #title, so the tools read the label every window carries."

	self assert: (MCPToolReadScreen new titleOf: (SystemWindow labelled: 'Plain Window')) equals: 'Plain Window'
]
