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

{ #category : 'private - frames' }
MCPCompileMethodCommand >> compileIntoFrame: aFrameRef [
	"Repairing the method a paused frame stopped in is compilation with a narrower scope: the class
	and the selector come from the frame, and the computation carries on once the edit is accepted."

	| debugRequest frameResult |
	debugRequest := MCPUpdateDebugMethodRequest new
		                operation: 'update';
		                sessionId: (aFrameRef findTokens: '/') first;
		                frameRef: aFrameRef;
		                methodSource: self request methodSource;
		                ignoreCritiques: self request force;
		                includeReceiver: true;
		                yourself.
	frameResult := (MCPUpdateDebugMethodCommand tool: self tool request: debugRequest) execute.
	^ frameResult isError
		  ifTrue: [ self tool errorResultText: frameResult summary details: frameResult errorDetails ]
		  ifFalse: [ self tool successResultText: frameResult summary data: frameResult data warnings: frameResult warnings ]
]

{ #category : 'executing' }
MCPCompileMethodCommand >> execute [

	| behavior changeKind compiledMethod methodReference methodSource result selector |
	self request frame ifNotNil: [ :frameRef | ^ self compileIntoFrame: frameRef ].
	^ self tool
		  executeMutationAction: 'compile'
		  force: self request force
		  requestedContext: self request requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  methodSource := self request methodSource.
				  selector := [ self selectorForMethodSource: methodSource ]
					              on: Exception
					              do: [ :error | self signalCompileFailure: error methodSource: methodSource ].
				  changeKind := (behavior includesSelector: selector)
					                ifTrue: [ 'replaced' ]
					                ifFalse: [ 'created' ].
				  selector := [ behavior compile: methodSource classified: self request protocol ]
					              on: Exception
					              do: [ :error | self signalCompileFailure: error methodSource: methodSource ].
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

{ #category : 'private - errors' }
MCPCompileMethodCommand >> signalCompileFailure: anError methodSource: methodSource [

	anError mcpCommandErrorDo: [ :commandError | commandError signal ] otherwise: [ :compileError |
			(self tool
				 commandErrorForCompileFailure: compileError
				 methodSource: methodSource
				 requestedContext: self request requestedContext
				 summary:
				 (self tool failureMessageForCompileClassNamed: self request className classSide: self request classSide error: compileError))
				signal ]
]
