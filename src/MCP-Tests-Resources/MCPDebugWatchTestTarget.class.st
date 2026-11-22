"
Target methods for debug_watch tests. Some assign a variable more than once and take an argument, so a probe has something to record on entry and on every write; others are one statement, a return or a message, which a probe on entry must find a node in.
"
Class {
	#name : 'MCPDebugWatchTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'fixtures' }
MCPDebugWatchTestTarget class >> doubleOf: n [

	| doubled |
	doubled := n.
	doubled := doubled * 2.
	^ doubled
]

{ #category : 'fixtures' }
MCPDebugWatchTestTarget class >> echo: n [

	^ n
]

{ #category : 'fixtures' }
MCPDebugWatchTestTarget >> failingSumTo: n [
	"The failure is intentional: debug_watch must report it and still answer what it recorded."

	| total |
	total := 0.
	1 to: n do: [ :i | total := total + i ].
	^ total / 0
]

{ #category : 'fixtures' }
MCPDebugWatchTestTarget >> itself [

	^ self
]

{ #category : 'fixtures' }
MCPDebugWatchTestTarget >> print: n [

	n printString
]

{ #category : 'fixtures' }
MCPDebugWatchTestTarget >> sumTo: n [

	| total step |
	total := 0.
	step := 1.
	1 to: n do: [ :i |
		step := i.
		total := total + step ].
	^ total
]
