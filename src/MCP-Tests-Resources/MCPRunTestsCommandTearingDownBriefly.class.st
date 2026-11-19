"
A test-running command that gives the test a timeout interrupts a tenth of a second for its tearDown, the shortest limit SUnit takes, rather than a second, so that a test of that tearDown answers sooner.
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
