"
Request object for transient debugger breakpoint operations.

It carries the operation, breakpoint id, target method identity, class side, target kind, and optional source interval for AST breakpoints.
"
Class {
	#name : 'MCPDebugBreakpointsRequest',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'breakpointId',
		'className',
		'selector',
		'classSide',
		'targetKind',
		'sourceStart',
		'sourceStop'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugBreakpointsRequest class >> fromRequest: aRequest tool: aTool operation: operationName [

	| targetKindName |
	(self supportedOperations includes: operationName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugBreakpointOperationUnsupported
				message: 'Unsupported debug breakpoint operation: ' , operationName asString , '.'
				details: {
						(#operation -> operationName).
						(#supportedOperations -> self supportedOperations) } asDictionary ].
	targetKindName := aRequest stringArgumentNamed: 'targetKind' default: 'method'.
	(self supportedTargetKinds includes: targetKindName) ifFalse: [
			MCPCommandError
				signalErrorCode: #DebugBreakpointTargetUnsupported
				message: 'Unsupported debug breakpoint targetKind: ' , targetKindName asString , '.'
				details: {
						(#targetKind -> targetKindName).
						(#supportedTargetKinds -> self supportedTargetKinds) } asDictionary ].
	^ self new
		  operation: operationName;
		  breakpointId: (aRequest stringArgumentNamed: 'breakpointId');
		  className: (aRequest stringArgumentNamed: 'className');
		  selector: (aRequest stringArgumentNamed: 'selector');
		  classSide: (aRequest booleanArgumentNamed: 'classSide' default: false);
		  targetKind: targetKindName;
		  sourceStart: (aRequest nonNegativeIntegerArgumentNamed: 'sourceStart' default: nil);
		  sourceStop: (aRequest nonNegativeIntegerArgumentNamed: 'sourceStop' default: nil);
		  yourself
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest class >> supportedOperations [

	^ #( 'list' 'set' 'remove' 'enable' 'disable' 'clear' )
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest class >> supportedTargetKinds [

	^ #( 'method' 'sourceInterval' )
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> breakpointId [

	^ breakpointId
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> breakpointId: aString [

	breakpointId := aString
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> className: aString [

	className := aString
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> operation [

	^ operation ifNil: [ 'list' ]
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> operation: aString [

	operation := aString
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> selector [

	^ selector
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> selector: aString [

	selector := aString
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> sourceStart [

	^ sourceStart
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> sourceStart: anInteger [

	sourceStart := anInteger
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> sourceStop [

	^ sourceStop
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> sourceStop: anInteger [

	sourceStop := anInteger
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> targetKind [

	^ targetKind ifNil: [ 'method' ]
]

{ #category : 'accessing' }
MCPDebugBreakpointsRequest >> targetKind: aString [

	targetKind := aString
]
