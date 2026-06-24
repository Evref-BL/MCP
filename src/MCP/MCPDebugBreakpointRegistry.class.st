"
In-image registry for transient MCP debugger breakpoints.

It assigns public breakpoint ids, keeps the underlying DebugPoint instances reachable, and centralizes enable, disable, remove, and clear behavior.
"
Class {
	#name : 'MCPDebugBreakpointRegistry',
	#superclass : 'Object',
	#instVars : [
		'breakpoints',
		'nextBreakpointNumber'
	],
	#classVars : [
		'Default'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'accessing' }
MCPDebugBreakpointRegistry class >> default [

	Default ifNil: [ Default := self new ].
	^ Default
]

{ #category : 'accessing' }
MCPDebugBreakpointRegistry class >> resetDefault [

	Default ifNotNil: [ Default removeAll ].
	Default := nil.
	^ self
]

{ #category : 'accessing' }
MCPDebugBreakpointRegistry >> breakpointRecordAt: breakpointId ifAbsent: absentBlock [

	^ breakpoints at: breakpointId ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPDebugBreakpointRegistry >> breakpointRecords [

	^ (breakpoints values asArray sort: [ :left :right |
		   left breakpointId <= right breakpointId ]) asArray
]

{ #category : 'initialization' }
MCPDebugBreakpointRegistry >> initialize [

	super initialize.
	breakpoints := Dictionary new.
	nextBreakpointNumber := 0
]

{ #category : 'private' }
MCPDebugBreakpointRegistry >> nextBreakpointId [

	nextBreakpointNumber := nextBreakpointNumber + 1.
	^ 'debug-breakpoint-' , nextBreakpointNumber asString
]

{ #category : 'registering' }
MCPDebugBreakpointRegistry >> registerDebugPoint: aDebugPoint className: aClassName selector: aSelector classSide: classSideBoolean targetKind: targetKindString sourceStart: startInteger sourceStop: stopInteger nodeClassName: nodeClassNameString [

	| breakpointId record |
	breakpointId := self nextBreakpointId.
	record := MCPDebugBreakpointRecord
		          breakpointId: breakpointId
		          debugPoint: aDebugPoint
		          className: aClassName
		          selector: aSelector
		          classSide: classSideBoolean
		          targetKind: targetKindString
		          sourceStart: startInteger
		          sourceStop: stopInteger
		          nodeClassName: nodeClassNameString
		          createdAt: DateAndTime now.
	breakpoints at: breakpointId put: record.
	^ record
]

{ #category : 'removing' }
MCPDebugBreakpointRegistry >> removeAll [

	breakpoints valuesDo: [ :each | each remove ].
	breakpoints removeAll.
	^ self
]

{ #category : 'removing' }
MCPDebugBreakpointRegistry >> removeBreakpointId: breakpointId ifAbsent: absentBlock [

	| record |
	record := breakpoints removeKey: breakpointId ifAbsent: absentBlock.
	record remove.
	^ record
]

{ #category : 'accessing' }
MCPDebugBreakpointRegistry >> size [

	^ breakpoints size
]
