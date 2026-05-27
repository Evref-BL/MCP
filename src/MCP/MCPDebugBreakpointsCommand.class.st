"
Implements transient debugger breakpoint operations.

It creates method-entry or source-interval DebugPoint breakpoints, lists registry state, and handles enable, disable, remove, and clear cleanup.
"
Class {
	#name : 'MCPDebugBreakpointsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request',
		'registry'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPDebugBreakpointsCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool
		  request: aRequest
		  registry: MCPDebugBreakpointRegistry default
]

{ #category : 'private - data' }
MCPDebugBreakpointsCommand >> capabilities [

	^ {
		  (#methodBreakpoints -> true).
		  (#sourceIntervalBreakpoints -> true).
		  (#fileLineBreakpoints -> false).
		  (#transient -> true).
		  (#operations -> MCPDebugBreakpointsRequest supportedOperations).
		  (#targetKinds -> MCPDebugBreakpointsRequest supportedTargetKinds) }
		  asDictionary
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> clearBreakpoints [

	| removedCount |
	removedCount := registry size.
	registry removeAll.
	^ MCPDebugToolResult okSummary: 'Debug breakpoints cleared.' data: {
			  (#removedCount -> removedCount).
			  (#breakpoints -> #(  )).
			  (#totalCount -> 0).
			  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - data' }
MCPDebugBreakpointsCommand >> dataForBreakpointRecord: aRecord [

	| data |
	data := aRecord asDictionary copy.
	data
		at: #totalCount put: registry size;
		at: #capabilities put: self capabilities.
	^ data
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> disableBreakpoint [

	| record |
	record := self requiredBreakpointRecord.
	record disable.
	^ MCPDebugToolResult
		  okSummary:
		  'Debug breakpoint ' , record breakpointId , ' disabled.'
		  data: (self dataForBreakpointRecord: record)
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> enableBreakpoint [

	| record |
	record := self requiredBreakpointRecord.
	record enable.
	^ MCPDebugToolResult
		  okSummary: 'Debug breakpoint ' , record breakpointId , ' enabled.'
		  data: (self dataForBreakpointRecord: record)
]

{ #category : 'executing' }
MCPDebugBreakpointsCommand >> execute [

	request operation = 'list' ifTrue: [ ^ self listBreakpoints ].
	request operation = 'set' ifTrue: [ ^ self setBreakpoint ].
	request operation = 'remove' ifTrue: [ ^ self removeBreakpoint ].
	request operation = 'enable' ifTrue: [ ^ self enableBreakpoint ].
	request operation = 'disable' ifTrue: [ ^ self disableBreakpoint ].
	request operation = 'clear' ifTrue: [ ^ self clearBreakpoints ].
	^ self signalUnsupportedOperation: request operation
]

{ #category : 'initialization' }
MCPDebugBreakpointsCommand >> initializeTool: aTool request: aRequest registry: aRegistry [

	tool := aTool.
	request := aRequest.
	registry := aRegistry.
	^ self
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> listBreakpoints [

	^ MCPDebugToolResult
		  okSummary: 'Debug breakpoints listed.'
		  data: self listData
]

{ #category : 'private - data' }
MCPDebugBreakpointsCommand >> listData [

	^ {
		  (#breakpoints
		   ->
			   (registry breakpointRecords collect: [ :each |
				    each asDictionary ]) asArray).
		  (#totalCount -> registry size).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'accessing' }
MCPDebugBreakpointsCommand >> registry [

	^ registry
]

{ #category : 'accessing' }
MCPDebugBreakpointsCommand >> registry: aRegistry [

	registry := aRegistry
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> removeBreakpoint [

	| data record |
	record := registry
		          removeBreakpointId: self requiredBreakpointId
		          ifAbsent: [ ^ self signalBreakpointNotFound ].
	data := self dataForBreakpointRecord: record.
	data at: #removed put: true.
	^ MCPDebugToolResult
		  okSummary: 'Debug breakpoint ' , record breakpointId , ' removed.'
		  data: data
]

{ #category : 'accessing' }
MCPDebugBreakpointsCommand >> request [

	^ request
]

{ #category : 'private - validation' }
MCPDebugBreakpointsCommand >> requireSetArguments [

	request className ifNil: [
		self signalRequiredArgumentNamed: 'className' ].
	request selector ifNil: [
		self signalRequiredArgumentNamed: 'selector' ]
]

{ #category : 'private - validation' }
MCPDebugBreakpointsCommand >> requireSourceIntervalArguments [

	request sourceStart ifNil: [
		self signalRequiredArgumentNamed: 'sourceStart' ].
	request sourceStop ifNil: [
		self signalRequiredArgumentNamed: 'sourceStop' ].
	request sourceStop < request sourceStart ifTrue: [
			MCPCommandError
				signalErrorCode: #DebugBreakpointSourceIntervalInvalid
				message:
				'sourceStop must be greater than or equal to sourceStart.'
				details: {
						(#sourceStart -> request sourceStart).
						(#sourceStop -> request sourceStop) } asDictionary ]
]

{ #category : 'private - validation' }
MCPDebugBreakpointsCommand >> requiredBreakpointId [

	request breakpointId ifNil: [ ^ self signalMissingBreakpointId ].
	^ request breakpointId
]

{ #category : 'private - validation' }
MCPDebugBreakpointsCommand >> requiredBreakpointRecord [

	^ registry
		  breakpointRecordAt: self requiredBreakpointId
		  ifAbsent: [ self signalBreakpointNotFound ]
]

{ #category : 'private - operations' }
MCPDebugBreakpointsCommand >> setBreakpoint [

	| method node debugPoint interval record |
	method := self targetMethod.
	node := self targetNodeInMethod: method.
	interval := self sourceIntervalForNode: node.
	debugPoint := DebugPointManager installNew: BreakDebugPoint on: node.
	record := registry
		          registerDebugPoint: debugPoint
		          className: request className
		          selector: request selector
		          classSide: request classSide
		          targetKind: request targetKind
		          sourceStart: interval first
		          sourceStop: interval last
		          nodeClassName: node class name asString.
	^ MCPDebugToolResult
		  okSummary: 'Debug breakpoint ' , record breakpointId , ' set.'
		  data: (self dataForBreakpointRecord: record)
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalBreakpointNotFound [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointNotFound
		  message: 'Debug breakpoint ' , request breakpointId asString
			  , ' was not found.'
		  details: { (#breakpointId -> request breakpointId) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalMissingBreakpointId [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointIdRequired
		  message: 'debug-breakpoints operation ' , request operation
			  , ' requires breakpointId.'
		  details: { (#operation -> request operation) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalRequiredArgumentNamed: argumentName [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointArgumentRequired
		  message:
			  'debug-breakpoints operation ' , request operation , ' requires '
			  , argumentName , '.'
		  details: {
				  (#operation -> request operation).
				  (#argumentName -> argumentName) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalSourceIntervalNotFoundForMethod: aCompiledMethod [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointSourceIntervalNotFound
		  message:
			  'No AST node contains source interval '
			  , request sourceStart asString , '-'
			  , request sourceStop asString , ' in ' , request className
			  , '>>#' , request selector , '.'
		  details: {
				  (#className -> request className).
				  (#classSide -> request classSide).
				  (#selector -> request selector).
				  (#sourceStart -> request sourceStart).
				  (#sourceStop -> request sourceStop).
				  (#methodSelector -> aCompiledMethod selector asString) }
				  asDictionary
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalUnsupportedOperation: operationName [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointOperationUnsupported
		  message:
			  'Unsupported debug breakpoint operation: '
			  , operationName asString , '.'
		  details: {
				  (#operation -> operationName).
				  (#supportedOperations
				   -> MCPDebugBreakpointsRequest supportedOperations) }
				  asDictionary
]

{ #category : 'private - errors' }
MCPDebugBreakpointsCommand >> signalUnsupportedTargetKind [

	^ MCPCommandError
		  signalErrorCode: #DebugBreakpointTargetUnsupported
		  message: 'Unsupported debug breakpoint targetKind: '
			  , request targetKind asString , '.'
		  details: {
				  (#targetKind -> request targetKind).
				  (#supportedTargetKinds
				   -> MCPDebugBreakpointsRequest supportedTargetKinds) }
				  asDictionary
]

{ #category : 'private - resolving' }
MCPDebugBreakpointsCommand >> sourceIntervalForNode: aNode [

	^ [ aNode sourceInterval ]
		  on: Error
		  do: [ :ignored | 0 to: 0 ]
]

{ #category : 'private - resolving' }
MCPDebugBreakpointsCommand >> sourceIntervalNodeInMethod: aCompiledMethod [

	| ast candidates nodes start stop |
	self requireSourceIntervalArguments.
	start := request sourceStart.
	stop := request sourceStop.
	ast := aCompiledMethod ast.
	nodes := OrderedCollection with: ast.
	nodes addAll: ast allChildren.
	candidates := OrderedCollection new.
	nodes do: [ :node |
			| interval |
			interval := self sourceIntervalForNode: node.
			((interval first <= start and: [ interval last >= stop ]) and: [
				 interval first > 0 ]) ifTrue: [ candidates add: node ] ].
	candidates ifEmpty: [
		^ self signalSourceIntervalNotFoundForMethod: aCompiledMethod ].
	^ (candidates asSortedCollection: [ :left :right |
			   (self sourceIntervalForNode: left) size
			   < (self sourceIntervalForNode: right) size ]) first
]

{ #category : 'private - resolving' }
MCPDebugBreakpointsCommand >> targetBehavior [

	| class |
	class := Smalltalk globals
		         at: request className asSymbol
		         ifAbsent: [
		         MCPCommandError signalMissingClassNamed: request className ].
	^ request classSide
		  ifTrue: [ class class ]
		  ifFalse: [ class ]
]

{ #category : 'private - resolving' }
MCPDebugBreakpointsCommand >> targetMethod [

	| behavior |
	self requireSetArguments.
	behavior := self targetBehavior.
	^ behavior compiledMethodAt: request selector asSymbol ifAbsent: [
			  MCPCommandError
				  signalMissingMethodInClassName: request className
				  classSide: request classSide
				  selector: request selector ]
]

{ #category : 'private - resolving' }
MCPDebugBreakpointsCommand >> targetNodeInMethod: aCompiledMethod [

	request targetKind = 'method' ifTrue: [ ^ aCompiledMethod ast ].
	request targetKind = 'sourceInterval' ifTrue: [
		^ self sourceIntervalNodeInMethod: aCompiledMethod ].
	^ self signalUnsupportedTargetKind
]

{ #category : 'accessing' }
MCPDebugBreakpointsCommand >> tool [

	^ tool
]
