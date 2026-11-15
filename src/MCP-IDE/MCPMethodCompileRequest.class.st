"
Parsed method_compile request.

It captures the target behavior, source, protocol, and warning policy supplied by the MCP transport request so compilation can run without repeatedly reading raw arguments.
"
Class {
	#name : 'MCPMethodCompileRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'methodSource',
		'protocol',
		'force',
		'sideGiven'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodCompileRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request tool: aTool
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> classSide [

	^ classSide = true
]

{ #category : 'converting' }
MCPMethodCompileRequest >> commandForTool: aTool [

	^ MCPCompileMethodCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> force [

	^ force = true
]

{ #category : 'initialization' }
MCPMethodCompileRequest >> initializeFromRequest: request tool: aTool [

	MCPImageLookup
		className: (request stringArgumentNamed: 'class')
		side: (request stringArgumentNamed: 'side')
		do: [ :baseName :isClassSide :isSideGiven |
				className := baseName.
				classSide := isClassSide.
				sideGiven := isSideGiven ].
	methodSource := request
		                argumentNamed: 'source'
		                ifAbsent: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'source' forTool: aTool ].
	protocol := request stringArgumentNamed: 'protocol'.
	force := request booleanArgumentNamed: 'force' default: false.
	^ self
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> methodSource [

	^ methodSource
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> protocol [

	^ protocol
]

{ #category : 'converting' }
MCPMethodCompileRequest >> requestedContext [

	^ {
		  (#class -> self className).
		  (#side -> (self classSide ifTrue: [ 'class' ] ifFalse: [ 'instance' ])) } asDictionary
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> sideGiven [
	"Whether the call said which side, by side or by a class written as Foo class. A method source's header may name a side only when the call did not."

	^ sideGiven = true
]
