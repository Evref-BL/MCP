"
A test-running command that gives the test a timeout interrupts the shortest time SUnit takes for its tearDown, rather than the command's, so that a test of that tearDown answers sooner.
"
Class {
	#name : 'MCPRunTestsCommandTearingDownBriefly',
	#superclass : 'MCPRunTestsCommand',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private - timeout' }
MCPRunTestsCommandTearingDownBriefly >> interruptedTearDownTimeLimit [

	^ 100 milliSeconds
]
