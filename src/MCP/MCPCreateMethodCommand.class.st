"
Command for creating or replacing one method from a parsed edit-method create request. The command compiles the supplied source and returns method metadata plus any included critiques.
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

{ #category : 'executing' }
MCPCreateMethodCommand >> execute [

	| behavior compiledMethod methodReference result selector |
	^ self tool
		  executeEditOperation: 'create'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
			  behavior := self tool
				              behaviorNamed: self request className
				              classSide: self request classSide.
			  selector := behavior
				              compile: self request methodSource
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
				            (self tool critiqueDataForMethod: compiledMethod) ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Created or replaced ' , methodReference , '.'
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

{ #category : 'accessing' }
MCPCreateMethodCommand >> tool [

	^ tool
]
