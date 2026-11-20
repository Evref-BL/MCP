"
Implements debug_watch's work: it installs non-halting probes on the given methods, evaluates an expression with them in place, and removes them again before it answers. Nothing survives the call: the probes are taken out in an ensure block, and with them the link installer Pharo made for them once no link is left.

Installing a probe recompiles its method and regenerates the AST, so every target is located as a source interval on the pristine AST first, and each node is found again in a freshly fetched AST immediately before its own probe goes in. A source interval alone is ambiguous, since a statement and the sequence containing it can share one, so a target is matched on its node kind as well.

It answers itself, holding what it probed, what the probes recorded and what the expression answered.
"
Class {
	#name : 'MCPDebugWatchCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'methodReferences',
		'variableNames',
		'expression',
		'targets',
		'recordedHits',
		'resultText'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPDebugWatchCommand class >> methods: methodReferences variables: variableNames run: aString [
	"Probe the methods methodReferences name, on every assignment to one of variableNames, or on entry when there are none, while aString runs."

	^ self new initializeMethods: methodReferences variables: variableNames run: aString
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> assignmentIntervalsIn: anAst forVariableNamed: aName [

	^ anAst allChildren
		  select: [ :each | each isAssignment and: [ each variable name = aName ] ]
		  thenCollect: [ :each | each sourceInterval ]
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

{ #category : 'private - executing' }
MCPDebugWatchCommand >> evaluateExpression [
	"The watched code is the point of the call, so its own failure is reported rather than raised."

	^ [ (Smalltalk compiler evaluate: expression) printString ]
		  on: Error
		  do: [ :error |
				  String streamContents: [ :stream |
						  stream << error class name.
						  ([ error messageText ]
							   on: Error
							   do: [ :ignored | '' ]) asString ifNotEmpty: [ :text | stream << ': ' << text ] ] ]
]

{ #category : 'executing' }
MCPDebugWatchCommand >> execute [
	"Answer myself, holding what was probed and what the probes recorded. They are removed however the expression ends."

	| installed |
	targets := self locatedTargets.
	targets ifEmpty: [ ^ self signalNoTargets ].
	installed := OrderedCollection new.
	recordedHits := [
		                targets doWithIndex: [ :target :index |
			                (self probeForTarget: target index: index) ifNotNil: [ :probe | installed add: probe ] ].
		                MCPDebugWatchRecorder recordingLimited: self hitLimit during: [ resultText := self evaluateExpression ] ]
		                ensure: [
				                installed do: [ :each |
						                [ each remove ]
							                on: Error
							                do: [ :ignored | nil ] ].
				                self releaseLinkInstaller ]
]

{ #category : 'defaults' }
MCPDebugWatchCommand >> hitLimit [

	^ 200
]

{ #category : 'initialization' }
MCPDebugWatchCommand >> initializeMethods: methodReferenceCollection variables: variableNameCollection run: aString [

	methodReferences := methodReferenceCollection.
	variableNames := variableNameCollection.
	expression := aString
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> locatedTargets [
	"Every target is located before anything is installed, because the first installation rewrites
	the AST the later ones would have been read from."

	| located |
	located := OrderedCollection new.
	methodReferences do: [ :reference |
			| method label |
			method := reference compiledMethod.
			label := reference printString.
			self watchesVariables
				ifTrue: [
						variableNames do: [ :variableName |
								(self assignmentIntervalsIn: method ast forVariableNamed: variableName) do: [ :interval |
										located add: {
												(#method -> label).
												(#compiledMethod -> method).
												(#watching -> variableName).
												(#label -> (String streamContents: [ :stream | stream << label << ' ' << variableName ])).
												(#expression -> variableName).
												(#interval -> interval).
												(#isAssignment -> true) } asDictionary ] ] ]
				ifFalse: [
						self entryNodeIn: method ast ifPresent: [ :entryNode |
								(self entryExpressionsIn: method ast) do: [ :name |
										located add: {
												(#method -> label).
												(#compiledMethod -> method).
												(#watching -> name).
												(#label -> (String streamContents: [ :stream | stream << label << ' ' << name ])).
												(#expression -> name).
												(#interval -> entryNode sourceInterval).
												(#isAssignment -> entryNode isAssignment) } asDictionary ] ] ] ].
	^ located
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> nodeMatching: aTarget ifFound: aBlock [
	"Answer what aBlock makes of the node, or nil when the method no longer has it. Installing an earlier probe regenerated this method's AST, so the node is found again now."

	^ (aTarget at: #compiledMethod) ast allChildren
		  detect: [ :each | each sourceInterval = (aTarget at: #interval) and: [ each isAssignment = (aTarget at: #isAssignment) ] ]
		  ifFound: aBlock
		  ifNone: [ nil ]
]

{ #category : 'accessing' }
MCPDebugWatchCommand >> recordedHits [
	"What the probes recorded, as the index of the target that recorded it and the value it saw, in order."

	^ recordedHits
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> releaseLinkInstaller [
	"Pharo's link installer, made by the first metalink, outlives the probes and reads again every method the image replaces. Before Pharo 12 that reading signals each global a replaced method names that the image no longer has, such as the old name of a class just renamed, and declares it in Undeclared. It goes once no link is installed, nor waits on a variable for the methods still to come, and the next link makes another."

	| registry |
	registry := MetaLink linkInstaller linksRegistry.
	(MetaLink allInstances anySatisfy: [ :each | each hasNodes or: [ registry hasPermaLinks: each ] ]) ifFalse: [
		MetaLink uninstallAll ]
]

{ #category : 'accessing' }
MCPDebugWatchCommand >> resultText [
	"What the expression answered, printed, or what it failed with."

	^ resultText
]

{ #category : 'private - probes' }
MCPDebugWatchCommand >> scriptForTarget: aTarget index: anIndex [
	"The script is compiled against the frame it fires in, so it can name the variable directly and
	let the compiler resolve it as a temporary, an argument or an instance variable."

	^ String streamContents: [ :stream |
		  stream << 'MCPDebugWatchRecorder record: ' << anIndex printString << ' value: ' << (aTarget at: #expression) ]
]

{ #category : 'private - errors' }
MCPDebugWatchCommand >> signalNoTargets [

	| message |
	message := self watchesVariables
		           ifTrue: [ 'None of the named variables are assigned in the named methods.' ]
		           ifFalse: [ 'None of the named methods has a statement to probe.' ].
	^ MCPCommandError signalErrorCode: #DebugWatchNothingToProbe message: message details: {
			  (#method -> (methodReferences collect: [ :each | each printString ] as: Array)).
			  (#variable -> variableNames asArray) } asDictionary
]

{ #category : 'accessing' }
MCPDebugWatchCommand >> targets [
	"What was probed, one per variable assignment or method entry, each with the method it is in and what it watches."

	^ targets
]

{ #category : 'testing' }
MCPDebugWatchCommand >> watchesVariables [

	^ variableNames isNotEmpty
]
