"
Command that compiles one method source from a parsed method_compile request.

It reports whether compilation created a new method or replaced an existing method, and includes any method critiques produced after compilation.
"
Class {
	#name : 'MCPCompileMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
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

	| behavior changeKind compiledMethod methodReference methodSource previousProtocolName result selector |
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
				  previousProtocolName := changeKind = 'replaced' ifTrue: [ self protocolNameOf: behavior >> selector ].
				  self tool signalTraitOriginBeforeCompiling: selector in: behavior unlessForced: self request force.
				  "Naming no protocol keeps the one the method is in. Pharo's own compile:classified: with nil does not promise that, so it is passed explicitly."
				  selector := [ behavior compile: methodSource classified: (self request protocol ifNil: [ previousProtocolName ]) ]
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
					  successResultText: (self
							   summaryFor: result changeKind
							   of: methodReference
							   from: previousProtocolName
							   to: (self protocolNameOf: compiledMethod))
					  data: result asDictionary
					  warnings: warningMessages , (self protocolWarningsFor: compiledMethod reference: methodReference) ]
		  failureSummary: [ :error |
		  self tool failureMessageForCompileClassNamed: self request className classSide: self request classSide error: error ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> isUnclassified: aCompiledMethod [

	^ (self protocolNameOf: aCompiledMethod)
		  ifNil: [ true ]
		  ifNotNil: [ :protocolName | protocolName = Protocol unclassified asString ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> protocolNameOf: aCompiledMethod [

	^ aCompiledMethod protocolName ifNotNil: [ :protocolName | protocolName asString ]
]

{ #category : 'private' }
MCPCompileMethodCommand >> protocolWarningsFor: aCompiledMethod reference: methodReference [
	"Nobody chose to file a method as unclassified: it is what is left when no protocol was named for it."

	(self isUnclassified: aCompiledMethod) ifFalse: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
			   stream << methodReference << ' has no protocol, so it is filed under ''' << Protocol unclassified asString
			   << '''. Name one with protocol, or move it with method_update.' ]) }
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

{ #category : 'private' }
MCPCompileMethodCommand >> summaryFor: changeKind of: methodReference from: previousProtocolName to: protocolName [
	"A method that changed protocol says so. Before protocol was optional, replacing a method's body meant naming a protocol, and naming another one moved the method without a word."

	^ String streamContents: [ :stream |
			  stream << (self changeSummaryVerbFor: changeKind) << ' ' << methodReference.
			  (changeKind = 'replaced' and: [ previousProtocolName ~= protocolName ]) ifTrue: [
					  stream << ', moving it from ' << (previousProtocolName ifNil: [ 'no protocol' ]) << ' to '
					  << (protocolName ifNil: [ 'no protocol' ]) ].
			  stream << '.' ]
]
