"
Command for compiling or replacing one method from a parsed edit-method compile request.
"
Class {
	#name : 'MCPCompileMethodCommand',
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
MCPCompileMethodCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPCompileMethodCommand >> execute [

	| behavior compiledMethod methodReference result selector |
	^ self tool
		  executeEditOperation: 'compile'
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
			  result := MCPMethodCompileResult
				            method: compiledMethod
				            critiques:
				            (self tool critiqueDataForMethod: compiledMethod) ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Compiled ' , methodReference , '.'
				  data: result asDictionary
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForCompileClassNamed: self request className
				  classSide: self request classSide
				  error: error ]
]

{ #category : 'initialization' }
MCPCompileMethodCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPCompileMethodCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCompileMethodCommand >> tool [

	^ tool
]
