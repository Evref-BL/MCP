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
		  (#frameRef -> (request frameRef ifNil: [
			    self frameRefForRecord: aRecord frameIndex: frameIndex ])).
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
					          ifNotNil: [ :syntaxNotice |
							          result := self
								                    syntaxFailureFor: syntaxNotice
								                    record: aRecord
								                    frameIndex: frameIndex ]
					          ifNil: [
							          result := self
								                    runtimeFailureFor: error
								                    record: aRecord
								                    frameIndex: frameIndex ].
				          nil ].
	result ifNotNil: [ ^ failureBlock value: result ].
	notice ifNotNil: [
			^ failureBlock value:
				  (self
					   syntaxFailureFor: notice
					   record: aRecord
					   frameIndex: frameIndex) ].
	^ answer
]

{ #category : 'private - data' }
MCPDebugEvaluateCommand >> evaluationWarnings [

	^ #( 'Evaluation may execute arbitrary Smalltalk in the selected debug frame and can mutate image state.' )
]

{ #category : 'executing' }
MCPDebugEvaluateCommand >> execute [

	| answer context data frameIndex record |
	record := self sessionRecordWithMatchingState.
	frameIndex := self selectedFrameIndex.
	context := self
		           selectedContextForRecord: record
		           frameIndex: frameIndex.
	answer := self
		          evaluateExpressionInContext: context
		          record: record
		          frameIndex: frameIndex
		          ifFailed: [ :commandResult | ^ commandResult ].
	data := self
		        resultDataFor: answer
		        record: record
		        frameIndex: frameIndex.
	^ MCPDebugToolResult
		  okSummary:
		  'Debug expression evaluated for ' , record sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
]

{ #category : 'private - frames' }
MCPDebugEvaluateCommand >> frameRefForRecord: aRecord frameIndex: frameIndex [

	^ aRecord sessionId , '/' , aRecord stateId , '/frame-'
	  , frameIndex asString
]

{ #category : 'private - printing' }
MCPDebugEvaluateCommand >> limitedPrintStringOf: anObject [

	^ [
	  anObject printStringLimitedTo: request resultPreviewCharacterLimit ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'private - data' }
MCPDebugEvaluateCommand >> resultDataFor: answer record: aRecord frameIndex: frameIndex [

	| frameRef warnings |
	frameRef := request frameRef ifNil: [
		            self frameRefForRecord: aRecord frameIndex: frameIndex ].
	warnings := self evaluationWarnings.
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
		  (#warnings -> warnings).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> runtimeFailureFor: anError record: aRecord frameIndex: frameIndex [

	| details |
	details := tool errorDetailsFor: anError.
	details addAll:
		(self debugLocationDetailsForRecord: aRecord frameIndex: frameIndex).
	details
		at: #errorCode put: 'DebugEvaluationFailed';
		at: #evaluationErrorClass put: anError class name.
	^ MCPDebugToolResult
		  errorSummary: (tool runtimeFailureMessageFor: anError)
		  details: details
]

{ #category : 'private - frames' }
MCPDebugEvaluateCommand >> selectedContextForRecord: aRecord frameIndex: frameIndex [

	| contexts stateInfo |
	stateInfo := MCPDebugStateInfo fromRecord: aRecord request: request.
	contexts := stateInfo rawContexts.
	^ contexts
		  at: frameIndex + 1
		  ifAbsent: [
		  self signalMissingFrameIndex: frameIndex record: aRecord ]
]

{ #category : 'private - frames' }
MCPDebugEvaluateCommand >> selectedFrameIndex [

	| frameToken index suffix tokens |
	request frameRef ifNil: [ ^ 0 ].
	tokens := request frameRef findTokens: '/'.
	tokens size >= 3 ifFalse: [ ^ self signalInvalidFrameReference ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
		^ self signalInvalidFrameReference ].
	suffix := frameToken allButFirst: 6.
	index := [ suffix asInteger ]
		         on: Error
		         do: [ :error | ^ self signalInvalidFrameReference ].
	index < 0 ifTrue: [ ^ self signalInvalidFrameReference ].
	^ index
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> signalInvalidFrameReference [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameReferenceInvalid
		  message:
		  'Invalid debug frame reference: ' , request frameRef asString
		  , '.'
		  details: { (#frameRef -> request frameRef) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> signalMissingFrameIndex: frameIndex record: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameNotFound
		  message:
			  'Debug frame ' , frameIndex asString
			  , ' was not found for session ' , aRecord sessionId , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameIndex -> frameIndex).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)) }
				  asDictionary
]

{ #category : 'private - errors' }
MCPDebugEvaluateCommand >> syntaxFailureFor: aNotice record: aRecord frameIndex: frameIndex [

	| details |
	details := tool errorDetailsFor: aNotice.
	details addAll:
		(self debugLocationDetailsForRecord: aRecord frameIndex: frameIndex).
	details
		at: #errorCode put: 'DebugEvaluationSyntaxError';
		at: #description put: 'Compilation failed before evaluation.'.
	^ MCPDebugToolResult
		  errorSummary: (tool syntaxFailureMessageFor: aNotice)
		  details: details
]
