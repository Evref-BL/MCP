"
Implements debug_watch.

It installs non-halting Pharo WatchDebugPoints on the requested methods, evaluates the expression with them in place, and removes them again before answering what they recorded. Nothing survives the call: the probes are the whole state, and they are taken out in an ensure block.

Installing a probe recompiles its method and regenerates the AST, so every target is located as a source interval on the pristine AST first, and each node is found again in a freshly fetched AST immediately before its own probe goes in. A source interval alone is ambiguous, since a statement and the sequence containing it can share one, so a target is matched on its node kind as well.
"
Class {
	#name : 'MCPDebugWatchCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - probes' }
MCPDebugWatchCommand >> assignmentIntervalsIn: anAst forVariableNamed: aName [

	^ (anAst allChildren select: [ :each | each isAssignment and: [ each variable name = aName ] ]) collect: [ :each |
		  each sourceInterval ]
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> entryExpressionsIn: anAst [
	"What a method was given is the question a probe on its entry answers; a method given nothing
	can still say who received the call."

	| names |
	names := anAst arguments collect: [ :each | each name ].
	^ names ifEmpty: [ #( 'self' ) ]
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> entryNodeIn: anAst ifPresent: aBlock [
	"A method node cannot carry a watch, so its first statement stands for entering it."

	^ anAst body statements ifEmpty: [ nil ] ifNotEmpty: [ :statements | aBlock value: statements first ]
]

{ #category : 'private - data' }
MCPDebugWatchCommand >> dataForHits: recordedHits targets: targets result: resultText [
	"Several probes can watch one variable, since it may be assigned in several places. They read as
	one series, so what is being watched is stated once rather than on every value."

	| groups order |
	groups := Dictionary new.
	order := OrderedCollection new.
	targets doWithIndex: [ :target :index |
			| label |
			label := target at: #label.
			(groups includesKey: label) ifFalse: [
					order add: label.
					groups
						at: label
						put: {
								(#method -> (target at: #method)).
								(#watching -> (target at: #watching)).
								(#values -> OrderedCollection new) } asDictionary ] ].
	recordedHits do: [ :hit |
			| label |
			label := (targets at: hit key) at: #label.
			((groups at: label) at: #values) add: hit value ].
	^ {
		  (#result -> resultText).
		  (#watched -> ((order collect: [ :label |
				     | group |
				     group := groups at: label.
				     group at: #values put: (group at: #values) asArray.
				     group ]) asArray)) } asDictionary
]

{ #category : 'executing' }
MCPDebugWatchCommand >> execute [

	| targets recordedHits resultText installed |
	targets := self targets.
	targets ifEmpty: [ ^ self signalNoTargets ].
	installed := OrderedCollection new.
	^ [
	  targets doWithIndex: [ :target :index |
			  (self probeForTarget: target index: index) ifNotNil: [ :probe | installed add: probe ] ].
	  resultText := nil.
	  recordedHits := MCPDebugWatchRecorder recordingLimited: self hitLimit during: [ resultText := self evaluateExpression ].
	  self resultForHits: recordedHits targets: targets result: resultText ]
		  ensure: [ installed do: [ :each | [ each remove ] on: Error do: [ :ignored | nil ] ] ]
]

{ #category : 'private - executing' }
MCPDebugWatchCommand >> evaluateExpression [
	"The watched code is the point of the call, so its own failure is reported rather than raised."

	^ [ (Smalltalk compiler evaluate: request expression) printString ]
		  on: Error
		  do: [ :error | error class name , ': ' , ([ error messageText ] on: Error do: [ :ignored | '' ]) asString ]
]

{ #category : 'defaults' }
MCPDebugWatchCommand >> hitLimit [

	^ 200
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> nodeMatching: aTarget [
	"Installing an earlier probe regenerated this method's AST, so the node is found again now."

	| ast |
	ast := (aTarget at: #compiledMethod) ast.
	^ ast allChildren
		  detect: [ :each | each sourceInterval = (aTarget at: #interval) and: [ each isAssignment = (aTarget at: #isAssignment) ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [

	| node probe |
	node := self nodeMatching: aTarget.
	node ifNil: [ ^ nil ].
	probe := DebugPointManager installNew: WatchDebugPoint on: node withBehaviors: { ScriptBehavior }.
	(probe getBehavior: ScriptBehavior) script: (self scriptForTarget: aTarget index: anIndex).
	^ probe
]

{ #category : 'private - results' }
MCPDebugWatchCommand >> resultForHits: recordedHits targets: targets result: resultText [

	| summary |
	summary := (self tool textForCount: recordedHits size noun: 'value') , ' recorded from '
	           , (self tool textForCount: targets size noun: 'probe') , '.'.
	^ MCPDebugToolResult
		  okSummary: summary
		  data: (self dataForHits: recordedHits targets: targets result: resultText)
		  warnings: (recordedHits size >= self hitLimit
				   ifTrue: [ { 'Recording stopped at ' , self hitLimit printString , ' values.' } ]
				   ifFalse: [ #(  ) ])
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> scriptForTarget: aTarget index: anIndex [
	"The script is compiled against the frame it fires in, so it can name the variable directly and
	let the compiler resolve it as a temporary, an argument or an instance variable."

	^ 'MCPDebugWatchRecorder record: ' , anIndex printString , ' value: ' , (aTarget at: #expression)
]

{ #category : 'private - errors' }
MCPDebugWatchCommand >> signalNoTargets [

	| message |
	message := request watchesVariables
		           ifTrue: [ 'None of the named variables are assigned in the named methods.' ]
		           ifFalse: [ 'None of the named methods has a statement to probe.' ].
	^ MCPCommandError
		  signalErrorCode: #DebugWatchNothingToProbe
		  message: message
		  details: {
				  (#method -> (request methodReferences collect: [ :each | each printString ]) asArray).
				  (#variable -> request variableNames asArray) } asDictionary
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> targets [
	"Every target is located before anything is installed, because the first installation rewrites
	the AST the later ones would have been read from."

	| targets |
	targets := OrderedCollection new.
	request methodReferences do: [ :reference |
			| method label |
			method := self methodForReference: reference.
			label := reference printString.
			request watchesVariables
				ifTrue: [
						request variableNames do: [ :variableName |
								(self assignmentIntervalsIn: method ast forVariableNamed: variableName) do: [ :interval |
										targets add: {
												(#method -> label).
												(#compiledMethod -> method).
												(#watching -> variableName).
												(#label -> (label , ' ' , variableName)).
												(#expression -> variableName).
												(#interval -> interval).
												(#isAssignment -> true) } asDictionary ] ] ]
				ifFalse: [
						self entryNodeIn: method ast ifPresent: [ :entryNode |
								(self entryExpressionsIn: method ast) do: [ :name |
										targets add: {
												(#method -> label).
												(#compiledMethod -> method).
												(#watching -> name).
												(#label -> (label , ' ' , name)).
												(#expression -> name).
												(#interval -> entryNode sourceInterval).
												(#isAssignment -> entryNode isAssignment) } asDictionary ] ] ] ].
	^ targets
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> methodForReference: aReference [

	| behavior |
	behavior := self class environment at: aReference className asSymbol ifAbsent: [
		            MCPCommandError signalMissingClassNamed: aReference className ].
	behavior := aReference classSide
		            ifTrue: [ behavior class ]
		            ifFalse: [ behavior ].
	^ behavior
		  compiledMethodAt: aReference selector asSymbol
		  ifAbsent: [
		  MCPCommandError
			  signalMissingMethodInClassName: aReference className
			  classSide: aReference classSide
			  selector: aReference selector ]
]
