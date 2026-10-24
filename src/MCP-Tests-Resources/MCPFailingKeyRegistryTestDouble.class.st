"
Tool registry that cannot file the first entry it is handed.

It lets a test check that a discovery pass which failed partway is tried again, rather than leaving the registry claiming classes it never filed.
"
Class {
	#name : 'MCPFailingKeyRegistryTestDouble',
	#superclass : 'MCPToolRegistry',
	#instVars : [
		'failuresLeft'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'entries' }
MCPFailingKeyRegistryTestDouble >> failNextFiling [
	"Arm the double, so the next entry it is handed cannot be filed."

	failuresLeft := 1
]

{ #category : 'entries' }
MCPFailingKeyRegistryTestDouble >> keyFor: anEntry [

	failuresLeft ifNil: [ ^ super keyFor: anEntry ].
	failuresLeft isZero ifFalse: [
			failuresLeft := failuresLeft - 1.
			Error signal: 'cannot file this entry yet' ].
	^ super keyFor: anEntry
]
