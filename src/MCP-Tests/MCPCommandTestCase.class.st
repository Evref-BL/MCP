"
Common base class for command tests that create and clean up temporary source artifacts.
"
Class {
	#name : 'MCPCommandTestCase',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'testing' }
MCPCommandTestCase class >> isAbstract [

	^ self = MCPCommandTestCase or: [ super isAbstract ]
]

{ #category : 'private - execution' }
MCPCommandTestCase >> aroundCommandExecution: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private - errors' }
MCPCommandTestCase >> captureCommandError: aBlock [

	^ [
		  self aroundCommandExecution: [ aBlock value ].
		  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private - execution' }
MCPCommandTestCase >> executeCommand: aCommand [

	^ self aroundCommandExecution: [ aCommand execute ]
]
