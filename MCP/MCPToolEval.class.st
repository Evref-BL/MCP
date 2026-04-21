Class {
	#name : 'MCPToolEval',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolEval >> executeWithArguments: arguments [

	| compiler notice answer |
	compiler := SmalltalkImage current compiler.
	compiler compilationContext isScripting: true.
	notice := nil.
	compiler failBlock: [ :aNotice |
		notice := aNotice.
		nil ].
	answer := [ compiler evaluate: (arguments at: #code) ]
		          on: Error
		          do: [ :error |
			          ^ { (MCPStructureTextContent text:
				             (self runtimeFailureMessageFor: error)) } ].
	notice ifNotNil: [
		^ { (MCPStructureTextContent text:
			   (self syntaxFailureMessageFor: notice)) } ].
	^ { (MCPStructureTextContent text: answer printString) }
]

{ #category : 'initialization' }
MCPToolEval >> initialize [

	super initialize.
	name := 'pharo-eval'.
	title := 'Execute Pharo Code'.
	description := 'Executes arbitrary Smalltalk code in the Pharo image and returns the result, may have side effects, and is less constrained than the dedicated MCP tools.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'code';
				                type: 'string';
				                description:
					                'The Smalltalk code to execute in the running Pharo image.') };
		               yourself.
	icons := {  }
]

{ #category : 'private' }
MCPToolEval >> runtimeFailureMessageFor: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Evaluation failed during execution (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText.
		  anError signalerContext ifNotNil: [ :context |
			  stream
				  nextPutAll: ' Signaler context: ';
				  nextPutAll: context printString ] ]
]

{ #category : 'private' }
MCPToolEval >> syntaxFailureMessageFor: aNotice [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Evaluation failed during compilation (';
			  nextPutAll: aNotice class name;
			  nextPutAll: '): ';
			  nextPutAll: aNotice messageText.
		  (aNotice respondsTo: #position) ifTrue: [
			  stream
				  nextPutAll: ' Position: ';
				  print: aNotice position ] ]
]
