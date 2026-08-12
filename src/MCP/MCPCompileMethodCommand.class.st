"
Command that compiles one method source from a parsed method_compile request.

It reports whether compilation created a new method or replaced an existing method, and includes any method critiques produced after compilation.
"
Class {
	#name : 'MCPCompileMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPCompileMethodCommand >> changeSummaryVerbFor: changeKindString [

	changeKindString = 'created' ifTrue: [ ^ 'Created' ].
	changeKindString = 'replaced' ifTrue: [ ^ 'Replaced' ].
	^ 'Changed'
]

{ #category : 'executing' }
MCPCompileMethodCommand >> execute [

	| behavior changeKind compiledMethod methodReference methodSource result selector |
	^ self tool
		  executeMutationAction: 'compile'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  methodSource := self request methodSource withInternalLineEndings.
				  selector := self selectorForMethodSource: methodSource.
				  changeKind := (behavior includesSelector: selector)
					                ifTrue: [ 'replaced' ]
					                ifFalse: [ 'created' ].
				  selector := behavior compile: methodSource classified: self request protocol.
				  compiledMethod := self tool reformattedMethodForBehavior: behavior selector: selector.
				  methodReference := self tool methodReferenceForBehavior: behavior selector: selector.
				  result := MCPMethodCompileResult
					            method: compiledMethod
					            critiques: (self tool critiqueDataForMethod: compiledMethod)
					            changeKind: changeKind ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (self changeSummaryVerbFor: result changeKind) , ' ' , methodReference , '.'
					  data: result asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
		  self tool failureMessageForCompileClassNamed: self request className classSide: self request classSide error: error ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> selectorForMethodSource: methodSourceString [

	| methodNode |
	methodNode := RBParser parseMethod: methodSourceString.
	self tool signalBlockingCritiquesForMethodNode: methodNode.
	^ methodNode selector
]
