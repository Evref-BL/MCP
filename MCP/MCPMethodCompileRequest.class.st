"
Parsed edit-method compile request. It captures the target behavior, source, protocol, and warning policy supplied by the MCP transport request so compilation can run without repeatedly reading raw arguments.
"
Class {
	#name : 'MCPMethodCompileRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'methodSource',
		'protocol',
		'force'
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

{ #category : 'accessing' }
MCPMethodCompileRequest >> force [

	^ force = true
]

{ #category : 'initialization' }
MCPMethodCompileRequest >> initializeFromRequest: request tool: aTool [

	className := request stringArgumentNamed: 'className'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	methodSource := request argumentNamed: 'methodSource' ifAbsent: [
		                MCPInvalidToolInput
			                signalMissingRequiredArgumentNamed: 'methodSource'
			                forTool: aTool ].
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
		  (#className -> self className).
		  (#classSide -> self classSide).
		  (#protocol -> self protocol) } asDictionary
]
