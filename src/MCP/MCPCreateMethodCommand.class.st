"
Command for creating or replacing one method from a parsed method_create request. The command compiles the supplied source and returns method metadata plus any included critiques.
"
Class {
	#name : 'MCPCreateMethodCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCreateMethodCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private' }
MCPCreateMethodCommand >> changeSummaryVerbFor: changeKindString [

	changeKindString = 'created' ifTrue: [ ^ 'Created' ].
	changeKindString = 'replaced' ifTrue: [ ^ 'Replaced' ].
	^ 'Changed'
]

{ #category : 'executing' }
MCPCreateMethodCommand >> execute [

	| behavior changeKind compiledMethod methodReference methodSource result selector |
	^ self tool
		  executeMutationAction: 'create'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
				  behavior := self tool
					              behaviorNamed: self request className
					              classSide: self request classSide.
				  methodSource := self request methodSource
					                  withInternalLineEndings.
				  selector := self selectorForMethodSource: methodSource.
				  changeKind := (behavior includesSelector: selector)
					                ifTrue: [ 'replaced' ]
					                ifFalse: [ 'created' ].
				  selector := behavior
					              compile: methodSource
					              classified: self request protocol.
				  compiledMethod := self tool
					                    reformattedMethodForBehavior: behavior
					                    selector: selector.
				  methodReference := self tool
					                     methodReferenceForBehavior: behavior
					                     selector: selector.
				  result := MCPMethodCreateResult
					            method: compiledMethod
					            critiques:
					            (self tool critiqueDataForMethod: compiledMethod)
					            changeKind: changeKind ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
						  (self changeSummaryVerbFor: result changeKind) , ' '
						  , methodReference , '.'
					  data: result asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForCompileClassNamed: self request className
					  classSide: self request classSide
					  error: error ]
]

{ #category : 'initialization' }
MCPCreateMethodCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPCreateMethodCommand >> request [

	^ request
]

{ #category : 'private' }
MCPCreateMethodCommand >> selectorForMethodSource: methodSourceString [

	^ (RBParser parseMethod: methodSourceString) selector
]

{ #category : 'accessing' }
MCPCreateMethodCommand >> tool [

	^ tool
]
