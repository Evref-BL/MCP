"
Command wrapper for edit-class create requests. It owns tool-level execution concerns such as warning handling, class comments, output shaping, and failure messages while delegating class installation to MCPCreateClassCommand.
"
Class {
	#name : 'MCPCreateClassToolCommand',
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
MCPCreateClassToolCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPCreateClassToolCommand >> execute [

	| result |
	^ self tool
		  executeEditOperation: 'create'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
			  result := (MCPCreateClassCommand
				             className: self request className
				             superclassName: self request superclassName
				             packageName: self request packageName
				             tag: self request tag
				             slots: self request slots
				             classSlots: self request classSlots
				             traits: self request traits
				             classTraits: self request classTraits
				             sharedVariables: self request sharedVariables
				             sharedPools: self request sharedPools
				             layout: self request layout) execute.
			  self request classComment ifNotNil: [
				  (MCPChangeClassCommentCommand
					   className: self request className
					   classComment: self request classComment) execute ] ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Created class ' , self request className , '.'
				  data: (self tool dataForResult: result operation: 'create')
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForCreateClassNamed: self request className
				  superclassName: self request superclassName
				  packageName: self request packageName
				  error: error ]
]

{ #category : 'initialization' }
MCPCreateClassToolCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPCreateClassToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCreateClassToolCommand >> tool [

	^ tool
]
