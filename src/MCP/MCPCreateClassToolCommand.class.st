"
Command wrapper for class creation requests.

It owns tool-level execution concerns such as warning handling, class comments, output shaping, and failure messages while delegating class installation to MCPCreateClassCommand.
"
Class {
	#name : 'MCPCreateClassToolCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPCreateClassToolCommand >> execute [

	| result |
	^ self tool
		  executeMutationAction: 'create'
		  force: false
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
					  (MCPChangeClassCommentCommand className: self request className classComment: self request classComment) execute ] ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Created class ' , self request className , '.'
					  data: (self tool dataForResult: result action: 'create')
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForCreateClassNamed: self request className
					  superclassName: self request superclassName
					  packageName: self request packageName
					  error: error ]
]
