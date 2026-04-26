Class {
	#name : 'MCPCommandTestCase',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
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
