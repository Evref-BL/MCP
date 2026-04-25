"
Evaluates arbitrary Smalltalk code in the running image. It is the escape hatch when no dedicated tool is a better fit.
"
Class {
	#name : 'MCPToolEvaluate',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolEvaluate >> commandForRequest: evaluateRequest [

	^ MCPEvaluateCommand
		  tool: self
		  request: evaluateRequest
		  resultPreviewCharacterLimit: self resultPreviewCharacterLimit
]

{ #category : 'defaults' }
MCPToolEvaluate >> defaultDescription [

	^ 'Evaluate arbitrary Smalltalk code and return a bounded preview of the result. Use this escape hatch only when a dedicated tool does not fit; it may mutate image state.'
]

{ #category : 'defaults' }
MCPToolEvaluate >> defaultIcons [

	^ { (self pngIconNamed: #go) }
]

{ #category : 'defaults' }
MCPToolEvaluate >> defaultInputSchema [

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
MCPToolEvaluate >> defaultName [

	^ 'evaluate'
]

{ #category : 'defaults' }
MCPToolEvaluate >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'resultClassName'
					   type: 'string'
					   description: 'The name of the evaluated result''s class.').
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
MCPToolEvaluate >> defaultTitle [

	^ 'Evaluate Code'
]

{ #category : 'executing' }
MCPToolEvaluate >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :evaluateRequest |
			  | commandResult |
			  commandResult := (self commandForRequest: evaluateRequest)
				                   execute.
			  commandResult isError
				  ifTrue: [
					  self
						  errorResultText: commandResult summary
						  details: commandResult errorDetails ]
				  ifFalse: [
					  self
						  successResultText: 'Code evaluated successfully.'
						  data: commandResult data ] ]
		  onError: [ :error :ignored |
			  self
				  errorResultText: (error messageText
						   ifNil: [ error asString ]
						   ifNotNil: [ :text | text ])
				  details: (self errorDetailsFor: error) ]
]

{ #category : 'private - request' }
MCPToolEvaluate >> parsedRequestFromToolRequest: request [

	^ MCPEvaluateRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolEvaluate >> resultPreviewCharacterLimit [

	^ 10000
]

{ #category : 'private' }
MCPToolEvaluate >> runtimeFailureMessageFor: anError [

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

{ #category : 'testing' }
MCPToolEvaluate >> shouldSaveImageAfterSuccessfulExecution [

	^ true
]

{ #category : 'private' }
MCPToolEvaluate >> syntaxFailureMessageFor: aNotice [

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
