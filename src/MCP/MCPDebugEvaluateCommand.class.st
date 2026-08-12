"
Evaluates a Smalltalk expression in the selected debugger frame.

The command compiles against the frame context so receiver and temporaries are visible, then returns structured success, syntax error, or runtime error details.
"
Class {
	#name : 'MCPDebugEvaluateCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - data' }
MCPDebugEvaluateCommand >> capabilities [

	^ {
		  (#contextEvaluation -> true).
		  (#resultExpansion -> false).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> debugLocationDetailsForRecord: aRecord frameIndex: frameIndex [

	^ {
		  (#sessionId -> aRecord sessionId).
		  (#stateId -> aRecord stateId).
		  (#frameRef -> (request frameRef ifNil: [ self frameRefForRecord: aRecord frameIndex: frameIndex ])).
		  (#expression -> request expression) } asDictionary
]

{ #category : 'private - evaluation' }
MCPDebugEvaluateCommand >> evaluateExpressionInContext: aContext record: aRecord frameIndex: frameIndex ifFailed: failureBlock [

	| answer compiler notice result |
	compiler := aContext compiler.
	compiler compilationContext isScripting: true.
	notice := nil.
	compiler failBlock: [ :aNotice |
			notice := aNotice.
			nil ].
	result := nil.
	answer := [ compiler evaluate: request expression ]
		          on: Exception
		          do: [ :error |
				          (PharoCompatibility syntaxNoticeFromException: error)
					          ifNotNil: [ :syntaxNotice | result := self syntaxFailureFor: syntaxNotice record: aRecord frameIndex: frameIndex ]
					          ifNil: [ result := self runtimeFailureFor: error record: aRecord frameIndex: frameIndex ].
				          nil ].
	result ifNotNil: [ ^ failureBlock value: result ].
	notice ifNotNil: [ ^ failureBlock value: (self syntaxFailureFor: notice record: aRecord frameIndex: frameIndex) ].
	^ answer
]

{ #category : 'private - data' }
MCPDebugEvaluateCommand >> evaluationWarnings [

	^ #( 'Evaluation may execute arbitrary Smalltalk in the selected debug frame and can mutate image state.' )
]

{ #category : 'executing' }
MCPDebugEvaluateCommand >> execute [

	| answer context data frameIndex record warnings |
	record := self sessionRecordWithMatchingState.
	frameIndex := self selectedFrameIndex.
	context := self selectedContextForRecord: record frameIndex: frameIndex.
	answer := self
		          evaluateExpressionInContext: context
		          record: record
		          frameIndex: frameIndex
		          ifFailed: [ :commandResult | ^ commandResult ].
	data := self resultDataFor: answer record: record frameIndex: frameIndex.
	warnings := self evaluationWarnings.
	warnings ifNotEmpty: [ data at: #warnings put: warnings ].
	^ MCPDebugToolResult okSummary: 'Debug expression evaluated for ' , record sessionId , '.' data: data warnings: warnings
]

{ #category : 'private - printing' }
MCPDebugEvaluateCommand >> limitedPrintStringOf: anObject [

	^ self limitedPrintStringOf: anObject limit: request resultPreviewCharacterLimit
]

{ #category : 'private - data' }
MCPDebugEvaluateCommand >> resultDataFor: answer record: aRecord frameIndex: frameIndex [

	| frameRef |
	frameRef := request frameRef ifNil: [ self frameRefForRecord: aRecord frameIndex: frameIndex ].
	^ {
		  (#sessionId -> aRecord sessionId).
		  (#stateId -> aRecord stateId).
		  (#frameRef -> frameRef).
		  (#expression -> request expression).
		  (#resultClassName -> answer class name asString).
		  (#resultPrintString -> (self limitedPrintStringOf: answer)).
		  (#hasResultVariableRef -> false).
		  (#resultVariableRef -> nil).
		  (#sideEffects -> 'possible').
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> runtimeFailureFor: anError record: aRecord frameIndex: frameIndex [

	| details |
	details := tool errorDetailsFor: anError.
	details addAll: (self debugLocationDetailsForRecord: aRecord frameIndex: frameIndex).
	details
		at: #errorCode put: 'DebugEvaluationFailed';
		at: #evaluationErrorClass put: anError class name.
	^ MCPDebugToolResult errorSummary: (tool runtimeFailureMessageFor: anError) details: details
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> syntaxFailureFor: aNotice record: aRecord frameIndex: frameIndex [

	| details |
	details := tool errorDetailsFor: aNotice.
	details addAll: (self debugLocationDetailsForRecord: aRecord frameIndex: frameIndex).
	details
		at: #errorCode put: 'DebugEvaluationSyntaxError';
		at: #description put: 'Compilation failed before evaluation.'.
	^ MCPDebugToolResult errorSummary: (tool syntaxFailureMessageFor: aNotice) details: details
]
