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
		'frame'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
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
MCPMethodCompileRequest >> frame [

	^ frame
]

{ #category : 'accessing' }
MCPMethodCompileRequest >> force [

	^ force = true
]

{ #category : 'initialization' }
MCPMethodCompileRequest >> initializeFromRequest: request tool: aTool [

	className := request stringArgumentNamed: 'className'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	methodSource := (request
		                 argumentNamed: 'source'
		                 ifAbsent: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'source' forTool: aTool ])
		                withInternalLineEndings.
	protocol := request stringArgumentNamed: 'protocol'.
	force := request booleanArgumentNamed: 'force' default: false.
	frame := request stringArgumentNamed: 'frame'.
	frame ifNil: [
			className ifNil: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'className' forTool: aTool ].
			protocol ifNil: [ MCPInvalidToolInput signalMissingRequiredArgumentNamed: 'protocol' forTool: aTool ] ].
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
		  (#className -> self className).
		  (#classSide -> self classSide) } asDictionary
]
