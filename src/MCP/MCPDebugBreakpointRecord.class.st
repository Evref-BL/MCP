"
Registry record for one transient debugger breakpoint.

It tracks the public breakpoint id, underlying DebugPoint, target method or source interval, resolved node class, and creation time so breakpoints can be listed and cleaned up.
"
Class {
	#name : 'MCPDebugBreakpointRecord',
	#superclass : 'Object',
	#instVars : [
		'breakpointId',
		'debugPoint',
		'className',
		'selector',
		'classSide',
		'targetKind',
		'sourceStart',
		'sourceStop',
		'nodeClassName',
		'createdAt'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugBreakpointRecord class >> breakpointId: breakpointString debugPoint: aDebugPoint className: classString selector: selectorString classSide: classSideBoolean targetKind: targetKindString sourceStart: startInteger sourceStop: stopInteger nodeClassName: nodeClassString createdAt: aDateAndTime [

	^ self new
		  initializeBreakpointId: breakpointString
		  debugPoint: aDebugPoint
		  className: classString
		  selector: selectorString
		  classSide: classSideBoolean
		  targetKind: targetKindString
		  sourceStart: startInteger
		  sourceStop: stopInteger
		  nodeClassName: nodeClassString
		  createdAt: aDateAndTime
]

{ #category : 'converting' }
MCPDebugBreakpointRecord >> asDictionary [

	^ {
		  (#breakpointId -> breakpointId).
		  (#className -> className).
		  (#selector -> selector).
		  (#classSide -> classSide).
		  (#targetKind -> targetKind).
		  (#sourceStart -> sourceStart).
		  (#sourceStop -> sourceStop).
		  (#nodeClassName -> nodeClassName).
		  (#enabled -> self enabled).
		  (#targetString -> self targetString).
		  (#createdAt -> createdAt asString) } asDictionary
]

{ #category : 'accessing' }
MCPDebugBreakpointRecord >> breakpointId [

	^ breakpointId
]

{ #category : 'accessing' }
MCPDebugBreakpointRecord >> debugPoint [

	^ debugPoint
]

{ #category : 'controlling' }
MCPDebugBreakpointRecord >> disable [

	debugPoint disable
]

{ #category : 'controlling' }
MCPDebugBreakpointRecord >> enable [

	debugPoint enable
]

{ #category : 'accessing' }
MCPDebugBreakpointRecord >> enabled [

	^ debugPoint enabled
]

{ #category : 'initialization' }
MCPDebugBreakpointRecord >> initializeBreakpointId: breakpointString debugPoint: aDebugPoint className: classString selector: selectorString classSide: classSideBoolean targetKind: targetKindString sourceStart: startInteger sourceStop: stopInteger nodeClassName: nodeClassString createdAt: aDateAndTime [

	breakpointId := breakpointString.
	debugPoint := aDebugPoint.
	className := classString.
	selector := selectorString.
	classSide := classSideBoolean.
	targetKind := targetKindString.
	sourceStart := startInteger.
	sourceStop := stopInteger.
	nodeClassName := nodeClassString.
	createdAt := aDateAndTime
]

{ #category : 'removing' }
MCPDebugBreakpointRecord >> remove [

	debugPoint ifNil: [ ^ self ].
	[ debugPoint remove ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'accessing' }
MCPDebugBreakpointRecord >> targetString [

	^ [ debugPoint targetString ]
		  on: Error
		  do: [ :error | className , '>>#' , selector ]
]
