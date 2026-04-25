"
Parsed edit-method create request. It captures the target behavior, source, protocol, and warning policy supplied by the MCP transport request so method creation or replacement can run without repeatedly reading raw arguments.
"
Class {
	#name : 'MCPMethodCreateRequest',
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
MCPMethodCreateRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request tool: aTool
]

{ #category : 'accessing' }
MCPMethodCreateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodCreateRequest >> classSide [

	^ classSide = true
]

{ #category : 'accessing' }
MCPMethodCreateRequest >> force [

	^ force = true
]

{ #category : 'initialization' }
MCPMethodCreateRequest >> initializeFromRequest: request tool: aTool [

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
MCPMethodCreateRequest >> methodSource [

	^ methodSource
]

{ #category : 'accessing' }
MCPMethodCreateRequest >> protocol [

	^ protocol
]

{ #category : 'converting' }
MCPMethodCreateRequest >> requestedContext [

	^ {
		  (#className -> self className).
		  (#classSide -> self classSide).
		  (#protocol -> self protocol) } asDictionary
]
