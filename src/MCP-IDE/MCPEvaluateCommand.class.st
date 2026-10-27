"
Command that evaluates Smalltalk code for the evaluate tool and returns a result data dictionary.
"
Class {
	#name : 'MCPEvaluateCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPEvaluateCommand class >> tool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	^ self new initializeTool: aTool request: aRequest resultPreviewCharacterLimit: anInteger
]

{ #category : 'executing' }
MCPEvaluateCommand >> execute [

	| answer compiler notice |
	compiler := SmalltalkImage current compiler.
	compiler compilationContext isScripting: true.
	notice := nil.
	compiler failBlock: [ :aNotice |
		notice := aNotice.
		nil ].
	answer := [ compiler evaluate: request code ]
		          on: Exception
		          do: [ :error |
			          (error isKindOf: Notification) ifTrue: [ self tool resumeNotification: error ].
			          error mcpSyntaxNotice ifNotNil: [ :syntaxNotice |
				          ^ self syntaxFailureFor: syntaxNotice ].
			          ^ self runtimeFailureFor: error ].
	notice ifNotNil: [ ^ self syntaxFailureFor: notice ].
	^ MCPEvaluateResult okData: (self resultDataFor: answer)
]

{ #category : 'initialization' }
MCPEvaluateCommand >> initializeTool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	tool := aTool.
	request := aRequest.
	resultPreviewCharacterLimit := anInteger.
	^ self
]

{ #category : 'private' }
MCPEvaluateCommand >> resultDataFor: anAnswer [
	"Report what a truncated preview left out. The full length is deliberately not computed: printStringLimitedTo: stops early, and forcing the whole print string is exactly the cost this preview exists to avoid."

	| data printString |
	printString := anAnswer printStringLimitedTo: resultPreviewCharacterLimit.
	data := Dictionary new.
	data at: #resultClassName put: anAnswer class name asString.
	data at: #resultPrintString put: printString.
	printString size < resultPreviewCharacterLimit ifTrue: [ ^ data ].
	data at: #truncated put: true.
	(anAnswer isCollection and: [ anAnswer isString not ]) ifTrue: [ data at: #resultSize put: anAnswer size ].
	^ data
]

{ #category : 'accessing' }
MCPEvaluateCommand >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'private' }
MCPEvaluateCommand >> runtimeFailureFor: anError [

	| details |
	details := tool errorDetailsFor: anError.
	anError mcpAddToolErrorDetailsTo: details.
	^ MCPEvaluateResult errorSummary: (tool runtimeFailureMessageFor: anError) details: details
]

{ #category : 'private' }
MCPEvaluateCommand >> sourceIndexFor: aPosition [
	"A notice can point one character past the end of the source, where the expression simply stopped, so the position is clamped rather than rejected."

	| source |
	aPosition ifNil: [ ^ nil ].
	source := request code.
	source ifEmpty: [ ^ nil ].
	^ (aPosition max: 1) min: source size
]

{ #category : 'private' }
MCPEvaluateCommand >> syntaxFailureFor: aNotice [

	| details index line |
	details := tool errorDetailsFor: aNotice.
	details at: #description put: 'Compilation failed before evaluation.'.
	index := self sourceIndexFor: aNotice position.
	line := index ifNotNil: [ request code lineNumberCorrespondingToIndex: index ].
	line ifNotNil: [
			details at: #line put: line.
			details at: #sourceLine put: (request code lineCorrespondingToIndex: index) ].
	^ MCPEvaluateResult errorSummary: (tool syntaxFailureMessageFor: aNotice line: line) details: details
]
