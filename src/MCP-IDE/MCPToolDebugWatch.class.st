"
Concrete debug_watch tool. It records what named variables hold while an expression runs, without stopping it.

This is print debugging without editing the method: Pharo WatchDebugPoints go in, the expression runs, the probes come out, and the values they saw are answered. Nothing is left installed and no debug session is created.
"
Class {
	#name : 'MCPToolDebugWatch',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugWatch class >> toolName [

	^ 'debug_watch'
]

{ #category : 'metadata' }
MCPToolDebugWatch >> additionalKeywords [

	^ #( 'watch' 'trace' 'log' 'print' 'value' 'variable' 'probe' 'observe' 'instrument' )
]

{ #category : 'private - results' }
MCPToolDebugWatch >> dataForHits: recordedHits targets: targets result: resultText [
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
					groups at: label put: {
							(#method -> (target at: #method)).
							(#watching -> (target at: #watching)).
							(#values -> OrderedCollection new) } asDictionary ] ].
	recordedHits do: [ :hit |
			| label |
			label := (targets at: hit key) at: #label.
			((groups at: label) at: #values) add: hit value ].
	^ {
		  (#result -> resultText).
		  (#watched -> (order
			    collect: [ :label |
					    | group |
					    group := groups at: label.
					    group at: #values put: (group at: #values) asArray.
					    group ]
			    as: Array)) } asDictionary
]

{ #category : 'metadata' }
MCPToolDebugWatch >> description [

	^ 'Record what variables hold while an expression runs, without stopping it. Probes are removed before the call answers, so nothing is left installed and no debug session is created.'
]

{ #category : 'metadata' }
MCPToolDebugWatch >> inputProperties [

	^ {
		  (self
			   stringOrArraySchemaNamed: 'method'
			   description: 'A method to probe, as Class>>selector or Class class>>selector. One of them, or several.'
			   itemDescription: 'One method.').
		  (self
			   stringOrArraySchemaNamed: 'variable'
			   description:
			   'A variable to record on every assignment to it. One of them, or several. Left out, the receiver is recorded when each method is entered.'
			   itemDescription: 'One variable.').
		  (self schemaPropertyNamed: 'run' type: 'string' description: 'Smalltalk to evaluate while the probes are installed.') }
]

{ #category : 'private - request' }
MCPToolDebugWatch >> methodReferencesIn: request [
	"The methods to probe, each read as Class>>selector or Class class>>selector. One that does not read so, or none at all, is the caller's mistake, said before any method is looked up."

	| references |
	references := (request stringCollectionArgumentNamed: 'method') collect: [ :each |
			              (MCPMethodReference fromString: each) ifNil: [
					              MCPCommandError
						              signalErrorCode: #MethodReferenceUnreadable
						              message: (String streamContents: [ :stream |
								               stream << 'Could not read ' << each printString << ' as a method. ' << MCPMethodReference helpText ])
						              details: { (#method -> each) } asDictionary ] ].
	references ifEmpty: [
			MCPCommandError
				signalErrorCode: #DebugWatchTargetMissing
				message: 'debug_watch needs at least one method to probe.'
				details: Dictionary new ].
	^ references
]

{ #category : 'metadata' }
MCPToolDebugWatch >> requiredInputProperties [

	^ #( 'method' 'run' )
]

{ #category : 'executing' }
MCPToolDebugWatch >> resultFor: request [

	^ self resultForWatch: (MCPDebugWatchCommand
			   methods: (self methodReferencesIn: request)
			   variables: (request stringCollectionArgumentNamed: 'variable')
			   run: (request stringArgumentNamed: 'run')) execute
]

{ #category : 'private - results' }
MCPToolDebugWatch >> resultForWatch: aWatch [
	"How many values the probes recorded, then what the expression answered and each watched variable's values."

	| hits |
	hits := aWatch recordedHits.
	^ self
		  successResultText: (String streamContents: [ :stream |
					   stream << (self textForCount: hits size noun: 'value') << ' recorded from '
					   << (self textForCount: aWatch targets size noun: 'probe') << '.' ])
		  data: (self dataForHits: hits targets: aWatch targets result: aWatch resultText)
		  warnings: (hits size >= aWatch hitLimit
				   ifTrue: [
				   { (String streamContents: [ :stream | stream << 'Recording stopped at ' << aWatch hitLimit printString << ' values.' ]) } ]
				   ifFalse: [ #(  ) ])
]

{ #category : 'metadata' }
MCPToolDebugWatch >> title [

	^ 'Watch Values While Code Runs'
]
