"
One version of a method that a change history records: what the change did to it (added, modified or removed), the source and protocol it left the method with, or for a removal the ones it took away, and the time the log gives it, if any. It also keeps the source and protocol the method had before the change, nil when there was no method, which is what putting it back as it was before that change installs.

Some changes are logged as two entries in a row, and make one version. method_compile logs a compile, then the change that formats its source: the version has the formatted source, says what the compile did, and keeps what came before the compile. Pharo 11 logs a removal as a move to the unclassified protocol, then the removal: the version is the removal.
"
Class {
	#name : 'MCPMethodVersionInfo',
	#superclass : 'Object',
	#instVars : [
		'number',
		'kind',
		'source',
		'protocol',
		'time',
		'previousSource',
		'previousProtocol',
		'isReformatted'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPMethodVersionInfo class >> fromChange: aMethodChange time: aDateAndTimeOrNil [
	"The version aMethodChange made. A removal's version is the method it took away."

	^ self new
		  setChange: aMethodChange time: aDateAndTimeOrNil;
		  yourself
]

{ #category : 'merging' }
MCPMethodVersionInfo >> adoptFormattingOf: aReformat [
	"Become one version with the change that formatted this one's source: what the method was left with is the formatted source. What it was before, and what the change did, are this version's."

	source := aReformat source.
	protocol := aReformat protocol.
	aReformat time ifNotNil: [ :reformatTime | time := reformatTime ].
	isReformatted := true
]

{ #category : 'converting' }
MCPMethodVersionInfo >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #version put: number.
	data at: #change put: kind.
	protocol ifNotNil: [ data at: #protocol put: protocol ].
	time ifNotNil: [ data at: #time put: time asString ].
	data at: #source put: source.
	^ data
]

{ #category : 'testing' }
MCPMethodVersionInfo >> isAddition [

	^ kind = 'added'
]

{ #category : 'merging' }
MCPMethodVersionInfo >> isFormattedBy: aVersion [
	"Whether aVersion, the next change to the method, only formats the source this version left, as method_compile does right after compiling. It changes neither the protocol, the code nor its comments. A version already formatted is not formatted again: method_compile formats once."

	isReformatted ifTrue: [ ^ false ].
	aVersion isModification ifFalse: [ ^ false ].
	(aVersion previousSource = source and: [ aVersion previousProtocol = protocol and: [ aVersion protocol = protocol ] ]) ifFalse: [
		^ false ].
	^ self source: source formatsAs: aVersion source
]

{ #category : 'testing' }
MCPMethodVersionInfo >> isModification [

	^ kind = 'modified'
]

{ #category : 'merging' }
MCPMethodVersionInfo >> isProtocolStepOf: aRemoval [
	"Whether this version only moved the method to another protocol as the first step of aRemoval, the next change to the method. Pharo 11 logs a removal so: the method filed as unclassified, then removed with the protocol it had."

	^ self isModification and: [
		  aRemoval isRemoval and: [
			  previousSource = source and: [ aRemoval source = source and: [ aRemoval protocol = previousProtocol ] ] ] ]
]

{ #category : 'testing' }
MCPMethodVersionInfo >> isRemoval [

	^ kind = 'removed'
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> kind [

	^ kind
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> number [

	^ number
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> number: anInteger [

	number := anInteger
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> previousProtocol [

	^ previousProtocol
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> previousSource [

	^ previousSource
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> protocol [

	^ protocol
]

{ #category : 'initialization' }
MCPMethodVersionInfo >> setChange: aMethodChange time: aDateAndTimeOrNil [

	kind := aMethodChange mcpVersionKind.
	source := aMethodChange methodAffected sourceCode.
	protocol := aMethodChange methodAffectedProtocol ifNotNil: [ :name | name asString ].
	time := aDateAndTimeOrNil.
	aMethodChange mcpMethodBeforeChange ifNotNil: [ :method |
			previousSource := method sourceCode.
			previousProtocol := method protocol ifNotNil: [ :name | name asString ] ].
	isReformatted := false
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> source [

	^ source
]

{ #category : 'private - merging' }
MCPMethodVersionInfo >> source: aString formatsAs: anotherString [
	"Whether the two sources differ in their layout alone: the same parse tree and the same comments. Either may no longer parse, and then it is not a formatting."

	| tree otherTree |
	tree := RBParser parseMethod: aString onError: [ :message :position | ^ false ].
	otherTree := RBParser parseMethod: anotherString onError: [ :message :position | ^ false ].
	^ tree = otherTree and: [
			  (tree allComments collect: [ :each | each contents ] as: Array)
			  = (otherTree allComments collect: [ :each | each contents ] as: Array) ]
]

{ #category : 'accessing' }
MCPMethodVersionInfo >> time [

	^ time
]
