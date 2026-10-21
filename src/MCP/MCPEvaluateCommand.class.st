"
Command that evaluates Smalltalk code for the evaluate tool and returns a result data dictionary.
"
Class {
	#name : 'MCPEvaluateCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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

	^ MCPEvaluateResult errorSummary: (tool runtimeFailureMessageFor: anError) details: (tool errorDetailsFor: anError)
]

{ #category : 'private' }
MCPEvaluateCommand >> syntaxFailureFor: aNotice [

	| details |
	details := tool errorDetailsFor: aNotice.
	details at: #description put: 'Compilation failed before evaluation.'.
	details at: #position put: aNotice position.
	^ MCPEvaluateResult errorSummary: (tool syntaxFailureMessageFor: aNotice) details: details
]
