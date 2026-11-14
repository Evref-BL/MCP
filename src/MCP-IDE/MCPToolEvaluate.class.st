"
Evaluates arbitrary Smalltalk code in the running image. It is the escape hatch when no dedicated tool is a better fit.
"
Class {
	#name : 'MCPToolEvaluate',
	#superclass : 'MCPTool',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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
		  properties: { (MCPStructureProperties new
				   name: 'code';
				   type: 'string';
				   description: 'Smalltalk code to run.';
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
	"An evaluation answers one value or one failure, and the JSON envelope around it repeats the summary, the class and the signaler context that the text already carries. A warning raised on the way is the exception: the value arrives looking usable, and the warning is what says it is not."

	| text |
	text := structuredContent
		        at: #data
		        ifPresent: [ :data | self resultTextFor: data ]
		        ifAbsent: [ self failureTextFor: structuredContent ].
	^ (structuredContent at: #warnings ifAbsent: [ #(  ) ]) ifEmpty: [ text ] ifNotEmpty: [ :warningDescriptions |
			  String streamContents: [ :stream |
					  stream << text.
					  warningDescriptions do: [ :each | stream << String lf << each ] ] ]
]

{ #category : 'metadata' }
MCPToolEvaluate >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolEvaluate >> defaultTimeoutSeconds [
	"Half of what PLexus waits for a call, which leaves room to read where the code is, let it unwind and answer before the client gives up. Agents' evaluations take milliseconds."

	^ 30
]

{ #category : 'metadata' }
MCPToolEvaluate >> description [

	^ 'The escape hatch: run arbitrary Smalltalk code when no tool fits; tool_search finds one. Returns result and Transcript.'
]

{ #category : 'private' }
MCPToolEvaluate >> endedItsOwnProcessMessage [

	^ 'Evaluation ended the process running it, so it has no value to answer.'
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
					  ifFalse: [
					  self successResultText: 'Code evaluated successfully.' data: commandResult data warnings: commandResult warnings ] ]
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
					  selectors do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPutAll: ', ' ] ].
			  self transcriptTextOn: stream for: error.
			  error at: #stackTrace ifPresent: [ :frames |
					  frames do: [ :each |
							  stream
								  nextPut: Character lf;
								  nextPutAll: each ] ] ]
]

{ #category : 'private' }
MCPToolEvaluate >> heldByHintLinesFor: processes [
	"An earlier evaluation ends at its own limit. A fork has none, and no tool can stop it, since stopping a process takes an evaluation."

	| lines |
	processes ifEmpty: [
		^ #( 'No other process holds the priority evaluations run at,' 'so code at a higher priority, such as another call, kept the processor.' ) ].
	lines := OrderedCollection new.
	(processes anySatisfy: [ :each | self isEvaluation: each ]) ifTrue: [
		lines add: 'An earlier evaluation stops at its own time limit; call again after it.' ].
	(processes anySatisfy: [ :each | (self isEvaluation: each) not ]) ifTrue: [
			lines
				add: 'A fork has no time limit; while it computes, evaluations may not start.';
				add: 'If it never ends, only an image restart ends it, losing what was not saved.';
				add: 'Fork long work at Processor userBackgroundPriority, below evaluations.' ].
	^ lines asArray
]

{ #category : 'private' }
MCPToolEvaluate >> heldByLinesFor: processes [
	"One line per process holding the priority evaluations run at. MCP runs nothing else there and a plain fork inherits it, so a process not named after this tool was forked by an evaluation, or by one of its forks. A frame is printed by its class and method only: printing a value would run the code that may be what never ends."

	^ processes collect: [ :each |
			  String streamContents: [ :stream |
					  (self isEvaluation: each)
						  ifTrue: [ stream nextPutAll: 'an earlier evaluation' ]
						  ifFalse: [
								  stream
									  nextPutAll: 'a process an evaluation forked, named ';
									  nextPutAll: each name trimBoth ].
					  each suspendedContext ifNotNil: [ :frame |
							  stream
								  nextPutAll: ', in ';
								  print: frame ] ] ]
]

{ #category : 'private' }
MCPToolEvaluate >> isEvaluation: aProcess [
	"An evaluation runs in a process named after this tool, and so does the process that stops one."

	^ aProcess name beginsWith: self name
]

{ #category : 'metadata' }
MCPToolEvaluate >> maximumTimeoutSeconds [
	"Long enough for a client that waits to run a long load inline, and a bound on what an evaluation nobody waits for any more can cost."

	^ 600
]

{ #category : 'private' }
MCPToolEvaluate >> notStartedMessageFor: seconds [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation did not start within ';
				  print: seconds;
				  nextPutAll: ' s, its time limit; none of it ran.' ]
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

	^ String streamContents: [ :stream |
			  stream nextPutAll: (data at: #resultPrintString).
			  (data includesKey: #truncated) ifTrue: [
					  stream
						  nextPut: Character lf;
						  nextPutAll: '[truncated'.
					  data at: #resultSize ifPresent: [ :size |
							  stream
								  nextPutAll: ': ';
								  nextPutAll: (data at: #resultClassName);
								  nextPutAll: ' of ';
								  print: size;
								  nextPutAll: ' elements' ].
					  stream nextPut: $] ].
			  self transcriptTextOn: stream for: data ]
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

{ #category : 'private - results' }
MCPToolEvaluate >> transcriptTextOn: stream for: aDictionary [
	"What the evaluation wrote to the Transcript, which its caller cannot see otherwise."

	aDictionary at: #transcript ifPresent: [ :text |
			stream
				nextPut: Character lf;
				nextPutAll: 'Transcript:';
				nextPut: Character lf;
				nextPutAll: text.
			(aDictionary includesKey: #transcriptTruncated) ifTrue: [
					stream
						nextPut: Character lf;
						nextPutAll: '[transcript truncated]' ] ]
]
