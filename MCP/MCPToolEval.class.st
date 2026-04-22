Class {
	#name : 'MCPToolEval',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolEval >> defaultDescription [

	^ 'Evaluate arbitrary Smalltalk code and return a bounded preview of the result. Use this escape hatch only when a dedicated tool does not fit; it may mutate image state.'
]

{ #category : 'defaults' }
MCPToolEval >> defaultIcons [

	^ { (self pngIconNamed: #scriptManager) }
]

{ #category : 'defaults' }
MCPToolEval >> defaultInputSchema [

	^ MCPStructureInputSchema new
		               type: 'object';
		               properties: { (MCPStructureProperties new
				                name: 'code';
				                type: 'string';
				                description:
					                'The Smalltalk code to execute in the running Pharo image.';
				                yourself) };
		               required: #( 'code' );
		               yourself
]

{ #category : 'defaults' }
MCPToolEval >> defaultName [

	^ 'evaluate'
]

{ #category : 'defaults' }
MCPToolEval >> defaultOutputSchema [

	^ self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'resultClassName'
					                 type: 'string'
					                 description:
					                 'The name of the evaluated result''s class.').
				                (self
					                 schemaPropertyNamed: 'resultPrintString'
					                 type: 'string'
					                 description:
						                 'A printString preview of the evaluated result, limited to '
						                 , self resultPreviewCharacterLimit printString
						                 , ' characters.') }
		                required: #( 'resultClassName' 'resultPrintString' )
]

{ #category : 'defaults' }
MCPToolEval >> defaultTitle [

	^ 'Evaluate Pharo Code'
]

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
	^ self successResultText: 'Code evaluated successfully.' data: {
			  (#resultClassName -> answer class name asString).
			  (#resultPrintString
			   ->
			   (answer printStringLimitedTo: self resultPreviewCharacterLimit)) }
			  asDictionary
]

{ #category : 'private' }
MCPToolEval >> resultPreviewCharacterLimit [

	^ 10000
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
