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

	^ 'evaluate'
]

{ #category : 'private - results' }
MCPToolEvaluate >> addTranscriptOf: anEvaluation to: aDictionary [
	"What the evaluation wrote to the Transcript, which its caller cannot see otherwise, and whether some of it was cut."

	anEvaluation transcriptText isEmptyOrNil ifTrue: [ ^ aDictionary ].
	aDictionary at: #transcript put: anEvaluation transcriptText.
	anEvaluation isTranscriptTruncated ifTrue: [ aDictionary at: #transcriptTruncated put: true ].
	^ aDictionary
]

{ #category : 'metadata' }
MCPToolEvaluate >> additionalKeywords [

	^ #( 'expression' 'smalltalk' )
]

{ #category : 'private - results' }
MCPToolEvaluate >> answerFor: anEvaluation [
	"What a call answers for an evaluation: its value, or why it has none."

	| ending |
	ending := anEvaluation ending.
	ending = #value ifTrue: [
		^ self successResultText: 'Code evaluated successfully.' data: (self dataFor: anEvaluation) warnings: anEvaluation warnings ].
	ending = #stopped ifTrue: [
			^ self
				  errorResultText: (self stopSummaryFor: anEvaluation stopReason of: anEvaluation)
				  details: (self stoppedDetailsFor: anEvaluation) ].
	ending = #notStarted ifTrue: [
			^ self
				  errorResultText: (self notStartedMessageFor: anEvaluation timeLimit)
				  details: (self notStartedDetailsFor: anEvaluation holders within: anEvaluation timeLimit) ].
	ending = #endedItsOwnProcess ifTrue: [
		^ self errorResultText: self endedItsOwnProcessMessage details: (self addTranscriptOf: anEvaluation to: Dictionary new) ].
	ending = #syntaxFailure ifTrue: [ ^ self syntaxFailureResultFor: anEvaluation ].
	ending = #runtimeFailure ifTrue: [
			^ self
				  errorResultText: (self runtimeFailureMessageFor: anEvaluation failure)
				  details: (self addTranscriptOf: anEvaluation to: anEvaluation failureDetails copy) ].
	^ self
		  errorResultText: (anEvaluation failure messageText ifNil: [ anEvaluation failure asString ])
		  details: anEvaluation failureDetails
]

{ #category : 'metadata' }
MCPToolEvaluate >> buildInputSchema [

	^ MCPStructureInputSchema
		  properties: {
				  (self schemaPropertyNamed: 'code' type: 'string' description: 'Smalltalk code to run.').
				  ((self
					    integerSchemaPropertyNamed: 'timeoutSeconds'
					    description: self timeoutSecondsDescription
					    default: self defaultTimeoutSeconds)
					   minimum: 1;
					   maximum: self maximumTimeoutSeconds;
					   yourself) }
		  required: #( 'code' )
]

{ #category : 'private' }
MCPToolEvaluate >> collapsedFrameLines: frameNames deeper: aBoolean [
	"A recursion fills every frame kept with one name, so a run of equal names is one line with its count. When the stack goes deeper than the frames kept, the run that reaches the last of them counts at least that many."

	| runs |
	runs := frameNames piecesCutWhere: [ :left :right | left ~= right ].
	^ (runs withIndexCollect: [ :run :index |
		   self frameLineFor: run first count: run size atLeast: (aBoolean and: [ index = runs size ]) ]) asArray
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

{ #category : 'private - results' }
MCPToolEvaluate >> dataFor: anEvaluation [
	"The value's class and preview, and what a cut preview left out. Code that ends on the Transcript answers the recorder that stood in for it while the code ran. To the caller that is the Transcript, so it is named as the one put back afterwards, and the text can leave the value out for what was written."

	| data |
	data := Dictionary new.
	anEvaluation answeredTheTranscript ifTrue: [
			data at: #resultClassName put: anEvaluation answer mcpTranscriptToRestore class name asString.
			data at: #resultPrintString put: 'Transcript'.
			data at: #answeredTranscript put: true.
			^ self addTranscriptOf: anEvaluation to: data ].
	data at: #resultClassName put: anEvaluation answer class name asString.
	data at: #resultPrintString put: anEvaluation preview.
	self addTranscriptOf: anEvaluation to: data.
	anEvaluation hasTruncatedPreview ifFalse: [ ^ data ].
	data at: #truncated put: true.
	anEvaluation answerSize ifNotNil: [ :size | data at: #resultSize put: size ].
	^ data
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
		  executeRequest: request
		  do: [
				  self answerFor: (MCPEvaluateCommand
						   code: (request stringArgumentNamed: 'code')
						   timeLimit: (request integerArgumentNamed: 'timeoutSeconds')
						   previewLimit: self resultPreviewCharacterLimit) execute ]
		  onError: [ :error |
				  self
					  errorResultText: (error messageText ifNil: [ error asString ] ifNotNil: [ :text | text ])
					  details: (self errorDetailsFor: error) ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> failureTextFor: structuredContent [
	"A stopped evaluation and one that never started have layouts of their own; every other failure reads as its summary, the failing line, what a message not understood was meant to be or the suggestions, the Transcript and the frames."

	| error |
	error := structuredContent at: #error ifAbsent: [ ^ super contentTextForStructuredContent: structuredContent ].
	(error includesKey: #stoppedIn) ifTrue: [ ^ self stoppedTextFor: structuredContent ].
	(error includesKey: #heldBy) ifTrue: [ ^ self notStartedTextFor: structuredContent ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: (structuredContent at: #summary ifAbsent: [ '' ]).
			  error at: #sourceLine ifPresent: [ :sourceLine |
					  stream
						  nextPut: Character lf;
						  nextPutAll: sourceLine ].
			  error at: #note ifPresent: [ :note |
					  stream
						  nextPut: Character lf;
						  nextPutAll: note ].
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
MCPToolEvaluate >> frameLineFor: aFrameName count: anInteger atLeast: aBoolean [

	anInteger = 1 ifTrue: [ ^ aFrameName ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: aFrameName;
				  nextPutAll: ', '.
			  aBoolean ifTrue: [ stream nextPutAll: 'at least ' ].
			  stream
				  print: anInteger;
				  nextPutAll: ' times in a row' ]
]

{ #category : 'private' }
MCPToolEvaluate >> frameNameFor: aContext [
	"A frame on one line, by its receiver's class, its method's class when another, and its selector, after [ ] in for a block. Pharo prints a frame so from 14 on; before, a block's frame prints the block's source, over as many lines as it has."

	^ String streamContents: [ :stream |
			  | receiverClass methodClass |
			  aContext isBlockContext ifTrue: [ stream nextPutAll: '[ ] in ' ].
			  receiverClass := aContext receiver class.
			  methodClass := aContext methodClass.
			  stream nextPutAll: receiverClass name.
			  methodClass == receiverClass ifFalse: [
					  stream
						  nextPut: $(;
						  nextPutAll: methodClass name;
						  nextPut: $) ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: aContext selector ]
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
								  nextPutAll: (self frameNameFor: frame) ] ] ]
]

{ #category : 'private' }
MCPToolEvaluate >> isEvaluation: aProcess [
	"An evaluation runs in a process MCPEvaluateCommand names, and so does the process that stops one."

	^ aProcess name beginsWith: MCPEvaluateCommand processName
]

{ #category : 'private - results' }
MCPToolEvaluate >> lines: someLines on: aStream [
	"Each on a line of its own, after what the stream already holds."

	someLines do: [ :each |
			aStream
				nextPut: Character lf;
				nextPutAll: each ]
]

{ #category : 'private' }
MCPToolEvaluate >> longerWorkHintLines [
	"Forking is the one way a stopped evaluation is told to run longer work: a raised limit is lost wherever the client waits less. The fork runs below every evaluation, so even one that never ends keeps none from starting, and an error in the work becomes its result rather than a file that never appears."

	^ 'Run longer work in a forked process that writes its result to a file:
[ | file result |
	file := FileLocator imageDirectory / ''result.txt''.
	file ensureDelete.
	result := [ "the work" ] on: Error do: [ :error | error description ].
	file writeStreamDo: [ :out | out print: result ] ]
		forkAt: Processor userBackgroundPriority
		named: ''result''
The file appears when the work ends; read it in a later call.
A fork has no time limit, and at this priority it holds up no evaluation.' lines
]

{ #category : 'metadata' }
MCPToolEvaluate >> maximumTimeoutSeconds [
	"Long enough for a client that waits to run a long load inline, and a bound on what an evaluation nobody waits for any more can cost."

	^ 600
]

{ #category : 'private' }
MCPToolEvaluate >> memoryStoppedMessageFor: bytes [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation stopped: the image''s memory grew by more than ';
				  nextPutAll: (self sizeTextFor: bytes);
				  nextPutAll: ' while it ran.' ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> notStartedDetailsFor: processes within: seconds [
	"What held the priority evaluations run at, and what to do about it."

	^ Dictionary new
		  at: #heldBy put: (self heldByLinesFor: processes);
		  at: #hint put: (self heldByHintLinesFor: processes);
		  at: #timeoutSeconds put: seconds;
		  yourself
]

{ #category : 'private' }
MCPToolEvaluate >> notStartedMessageFor: seconds [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation did not start within ';
				  print: seconds;
				  nextPutAll: ' s, its time limit; none of it ran.' ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> notStartedTextFor: structuredContent [
	"What kept the processor at the priority evaluations run at, then what to do about it. None of the code ran, so there is no Transcript to show."

	| error |
	error := structuredContent at: #error.
	^ String streamContents: [ :stream |
			  stream nextPutAll: (structuredContent at: #summary ifAbsent: [ '' ]).
			  (error at: #heldBy) ifNotEmpty: [ :processLines |
					  stream
						  nextPut: Character lf;
						  nextPutAll: 'Holding the priority evaluations run at:'.
					  self lines: processLines on: stream ].
			  self lines: (error at: #hint ifAbsent: [ #(  ) ]) on: stream ]
]

{ #category : 'private' }
MCPToolEvaluate >> resultPreviewCharacterLimit [

	^ 10000
]

{ #category : 'private - results' }
MCPToolEvaluate >> resultTextFor: data [
	"Code that ends on the Transcript answers the Transcript itself. When it wrote there, what it wrote is the answer, and a value line reading Transcript above it would say nothing more."

	((data at: #answeredTranscript ifAbsent: [ false ]) and: [ data includesKey: #transcript ]) ifTrue: [
		^ String streamContents: [ :stream | self writtenTranscriptOn: stream for: data ] ].
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
MCPToolEvaluate >> sizeTextFor: bytes [
	"In whole GB from 1 GB up, in whole MB below."

	| megabytes |
	megabytes := bytes // (1024 * 1024).
	^ megabytes >= 1024
		  ifTrue: [ (megabytes // 1024) printString , ' GB' ]
		  ifFalse: [ megabytes printString , ' MB' ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> sourceIndexFor: aPosition in: aString [
	"A notice can point one character past the end of the source, where the expression simply stopped, so the position is clamped rather than rejected."

	aPosition ifNil: [ ^ nil ].
	aString ifEmpty: [ ^ nil ].
	^ (aPosition max: 1) min: aString size
]

{ #category : 'private' }
MCPToolEvaluate >> stackStoppedMessageFor: frames [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation stopped: its stack passed ';
				  print: frames;
				  nextPutAll: ' frames, which an endless recursion does.' ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> stopSummaryFor: aReason of: anEvaluation [
	"What stopped an evaluation, with the bound it passed."

	aReason = #stackDepth ifTrue: [ ^ self stackStoppedMessageFor: anEvaluation stackDepthLimit ].
	aReason = #memoryGrowth ifTrue: [ ^ self memoryStoppedMessageFor: anEvaluation memoryGrowthLimit ].
	^ self stoppedMessageFor: anEvaluation timeLimit
]

{ #category : 'private - results' }
MCPToolEvaluate >> stoppedDetailsFor: anEvaluation [
	"Where the code was when it was stopped, each frame by its class and method only: printing a value would run the stopped code's own printOn:, which may be what never ends, or wait on a lock the stopped process holds."

	| details frames limit |
	limit := self errorStackTraceLimit.
	frames := anEvaluation stoppedFrames.
	details := Dictionary new.
	details at: #stoppedIn put: (self
			 collapsedFrameLines: ((frames first: (frames size min: limit)) collect: [ :each | self frameNameFor: each ] as: Array)
			 deeper: frames size > limit).
	details at: #hint put: self longerWorkHintLines.
	details at: #timeoutSeconds put: anEvaluation timeLimit.
	self addTranscriptOf: anEvaluation to: details.
	anEvaluation isStillUnwinding ifTrue: [ details at: #stillUnwinding put: true ].
	^ details
]

{ #category : 'private' }
MCPToolEvaluate >> stoppedMessageFor: seconds [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation stopped after ';
				  print: seconds;
				  nextPutAll: ' s, its time limit.' ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> stoppedTextFor: structuredContent [
	"Where the code was when it was stopped, then the one way the answer recommends to run longer work. The limit is not offered for raising: through a client that waits less, a raised limit loses the answer while the code goes on."

	| error |
	error := structuredContent at: #error.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (structuredContent at: #summary ifAbsent: [ '' ]);
				  nextPut: Character lf;
				  nextPutAll: 'What it changed before then stays changed.'.
			  (error at: #stillUnwinding ifAbsent: [ false ]) ifTrue: [
					  stream
						  nextPut: Character lf;
						  nextPutAll: 'Its ensure blocks were still running when this answer was sent.' ].
			  (error at: #stoppedIn) ifNotEmpty: [ :frameLines |
					  stream
						  nextPut: Character lf;
						  nextPutAll: 'Stopped in:'.
					  self lines: frameLines on: stream ].
			  self lines: (error at: #hint ifAbsent: [ #(  ) ]) on: stream.
			  self transcriptTextOn: stream for: error ]
]

{ #category : 'private' }
MCPToolEvaluate >> syntaxFailureMessageFor: aNotice line: aLineNumber [
	"An undeclared variable is named by MCP itself: Pharo 13's notice says only Undeclared variable, and Pharo 14's names it in the DoIt the code was compiled as, which the caller never wrote."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Evaluation failed during compilation (';
				  nextPutAll: aNotice class name;
				  nextPutAll: '): '.
			  aNotice mcpNoticeNode ifNil: [ stream nextPutAll: aNotice messageText ] ifNotNil: [ :node |
					  stream
						  nextPutAll: 'Undeclared variable: ';
						  nextPutAll: node name ].
			  aLineNumber ifNotNil: [
					  stream
						  nextPutAll: ' Line ';
						  print: aLineNumber ] ]
]

{ #category : 'private - results' }
MCPToolEvaluate >> syntaxFailureResultFor: anEvaluation [
	"Compilation failed, so the answer says on which line of the code, and shows it."

	| code details index line |
	code := anEvaluation code.
	details := anEvaluation failureDetails copy.
	details at: #description put: 'Compilation failed before evaluation.'.
	index := self sourceIndexFor: anEvaluation failure position in: code.
	line := index ifNotNil: [ code lineNumberCorrespondingToIndex: index ].
	line ifNotNil: [
			details at: #line put: line.
			details at: #sourceLine put: (code lineCorrespondingToIndex: index) ].
	^ self errorResultText: (self syntaxFailureMessageFor: anEvaluation failure line: line) details: details
]

{ #category : 'metadata' }
MCPToolEvaluate >> timeoutSecondsDescription [
	"Through a client that waits less than the limit, the answer is lost while the code goes on, so the way to run longer work is said here too."

	^ 'Stop the code after this many seconds; a limit longer than the client waits loses the answer. Fork longer work so that it writes its result to a file.'
]

{ #category : 'metadata' }
MCPToolEvaluate >> title [

	^ 'Evaluate Image Code'
]

{ #category : 'private - results' }
MCPToolEvaluate >> transcriptTextOn: stream for: aDictionary [
	"What the evaluation wrote to the Transcript, which its caller cannot see otherwise, on lines of its own after what came before."

	(aDictionary includesKey: #transcript) ifFalse: [ ^ self ].
	stream nextPut: Character lf.
	self writtenTranscriptOn: stream for: aDictionary
]

{ #category : 'private - results' }
MCPToolEvaluate >> writtenTranscriptOn: stream for: aDictionary [
	"What the evaluation wrote to the Transcript, under its label, and whether some of it was cut."

	stream
		nextPutAll: 'Transcript:';
		nextPut: Character lf;
		nextPutAll: (aDictionary at: #transcript).
	(aDictionary includesKey: #transcriptTruncated) ifTrue: [
			stream
				nextPut: Character lf;
				nextPutAll: '[transcript truncated]' ]
]
