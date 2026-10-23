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

{ #category : 'metadata' }
MCPToolEvaluate class >> groupName [

	^ self runtimeGroupName
]

{ #category : 'metadata' }
MCPToolEvaluate class >> toolName [

	^ 'image_evaluate'
]

{ #category : 'metadata' }
MCPToolEvaluate >> additionalKeywords [

	^ #( 'expression' 'smalltalk' )
]

{ #category : 'metadata' }
MCPToolEvaluate >> buildInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'code';
					   type: 'string';
					   description: 'The Smalltalk code to execute in the running Pharo image.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'frame';
					   type: 'string';
					   description:
						   'A frame reference from debug_session. Given, the code is evaluated in that paused frame, where the frame''s variables are in scope.';
					   yourself) };
		  required: #( 'code' );
		  yourself
]

{ #category : 'private - execution' }
MCPToolEvaluate >> commandForRequest: evaluateRequest [

	^ MCPEvaluateCommand tool: self request: evaluateRequest resultPreviewCharacterLimit: self resultPreviewCharacterLimit
]

{ #category : 'private - results' }
MCPToolEvaluate >> contentTextForStructuredContent: structuredContent [
	"An evaluation answers one value or one failure, and the JSON envelope around it repeats the summary, the class and the signaler context that the text already carries."

	^ structuredContent
		  at: #data
		  ifPresent: [ :data | self resultTextFor: data ]
		  ifAbsent: [ self failureTextFor: structuredContent ]
]

{ #category : 'metadata' }
MCPToolEvaluate >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolEvaluate >> description [

	^ 'Evaluate arbitrary Smalltalk code and return a bounded preview of the result. It may mutate image state. This is the escape hatch: before hand-writing a class, method, package, test or repository change, look for the dedicated tool with tool_search.'
]

{ #category : 'executing' }
MCPToolEvaluate >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :evaluateRequest |
				  | commandResult |
				  commandResult := (self commandForRequest: evaluateRequest) execute.
				  commandResult isError
					  ifTrue: [ self errorResultText: commandResult summary details: commandResult errorDetails ]
					  ifFalse: [ self successResultText: 'Code evaluated successfully.' data: commandResult data ] ]
		  onError: [ :error :ignored |
				  self
					  errorResultText: (error messageText ifNil: [ error asString ] ifNotNil: [ :text | text ])
					  details: (self errorDetailsFor: error) ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> failureTextFor: structuredContent [

	| error |
	error := structuredContent at: #error ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: (structuredContent at: #summary ifAbsent: [ '' ]).
			  error at: #sourceLine ifPresent: [ :sourceLine |
					  stream
						  nextPut: Character lf;
						  nextPutAll: sourceLine ].
			  error at: #suggestedSelectors ifPresent: [ :selectors |
					  stream
						  nextPut: Character lf;
						  nextPutAll: 'Did you mean: '.
					  selectors
						  do: [ :each | stream nextPutAll: each ]
						  separatedBy: [ stream nextPutAll: ', ' ] ].
			  error at: #stackTrace ifPresent: [ :frames |
					  frames do: [ :each |
							  stream
								  nextPut: Character lf;
								  nextPutAll: each ] ] ]
]

{ #category : 'private - request' }
MCPToolEvaluate >> parsedRequestFromToolRequest: request [

	^ MCPEvaluateRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolEvaluate >> resultPreviewCharacterLimit [

	^ 10000
]

{ #category : 'private - results' }
MCPToolEvaluate >> resultTextFor: data [

	| printString |
	printString := data at: #resultPrintString.
	(data includesKey: #truncated) ifFalse: [ ^ printString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: printString;
				  nextPut: Character lf;
				  nextPutAll: '[truncated'.
			  data
				  at: #resultSize
				  ifPresent: [ :size |
						  stream
							  nextPutAll: ': ';
							  nextPutAll: (data at: #resultClassName);
							  nextPutAll: ' of ';
							  print: size;
							  nextPutAll: ' elements' ].
			  stream nextPut: $] ]
]

{ #category : 'private' }
MCPToolEvaluate >> runtimeFailureMessageFor: anError [
	"The signaler context is the first frame of the stack trace the failure already reports, so it is not repeated here."

	| message |
	message := anError messageText ifNil: [ anError asString ] ifNotNil: [ :text | text asString ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation failed during execution (';
				  nextPutAll: anError class name;
				  nextPutAll: '): ';
				  nextPutAll: message ]
]

{ #category : 'private' }
MCPToolEvaluate >> syntaxFailureMessageFor: aNotice [
	"Compiling against a paused frame reports no line: the expression is the caller's, not a method's."

	^ self syntaxFailureMessageFor: aNotice line: nil
]

{ #category : 'private' }
MCPToolEvaluate >> syntaxFailureMessageFor: aNotice line: aLineNumber [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation failed during compilation (';
				  nextPutAll: aNotice class name;
				  nextPutAll: '): ';
				  nextPutAll: aNotice messageText.
			  aLineNumber ifNotNil: [
					  stream
						  nextPutAll: ' Line ';
						  print: aLineNumber ] ]
]

{ #category : 'metadata' }
MCPToolEvaluate >> title [

	^ 'Evaluate Image Code'
]
