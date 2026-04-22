Class {
	#name : 'MCPToolEval',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'executing' }
MCPToolEval >> executeWithArguments: arguments [

	| answer compiler notice |
	compiler := SmalltalkImage current compiler.
	compiler compilationContext isScripting: true.
	notice := nil.
	compiler failBlock: [ :aNotice |
		notice := aNotice.
		nil ].
	answer := [ compiler evaluate: (arguments at: #code) ]
		          on: Error
		          do: [ :error |
			          ^ self
				            errorResultText:
				            (self runtimeFailureMessageFor: error)
				            details: {
						            (#errorClass -> error class name).
						            (#message -> error messageText).
						            (#signalerContext
						             ->
						             (error signalerContext ifNotNil: [ :ctx |
							              ctx printString ])) } asDictionary ].
	notice ifNotNil: [
		^ self
			  errorResultText: (self syntaxFailureMessageFor: notice)
			  details: {
					  (#errorClass -> notice class name).
					  (#message -> notice messageText).
					  (#description -> 'Compilation failed before evaluation.').
					  (#position -> notice position) } asDictionary ].
	^ self
		  successResultText: 'Code evaluated successfully.'
		  data: { (#resultPrintString -> answer printString) } asDictionary
]

{ #category : 'initialization' }
MCPToolEval >> initialize [

	super initialize.
	name := 'eval'.
	title := 'Evaluate Pharo Code'.
	description := 'Evaluate arbitrary Smalltalk code in the running Pharo image. Prefer dedicated tools when possible; this tool is an escape hatch and may have side effects.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'code';
				                type: 'string';
				                description:
					                'The Smalltalk code to execute in the running Pharo image.';
				                yourself) };
		               required: #( 'code' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: { (self
				                 schemaPropertyNamed: 'resultPrintString'
				                 type: 'string'
				                 description:
				                 'The printString of the evaluated result.') }
		                required: #( 'resultPrintString' ).
	icons := { (self pngIconNamed: #scriptManager) }
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
