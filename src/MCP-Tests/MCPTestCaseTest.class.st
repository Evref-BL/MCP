"
Tests for what MCPTestCase gives every test it runs.
"
Class {
	#name : 'MCPTestCaseTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPTestCaseTest >> testPutsBackTheMonitorItReplaced [
	"A test run inside this one gets a history of its own too, and leaves this one's in place."

	| monitor inner |
	monitor := EpMonitor current.
	inner := self class selector: #testRunsWithAChangeHistoryOfItsOwn.
	self assert: inner run passed size equals: 1.
	self assert: EpMonitor current identicalTo: monitor
]

{ #category : 'tests' }
MCPTestCaseTest >> testRunsWithAChangeHistoryOfItsOwn [
	"Whatever the image's change history holds, a test reads an empty one, in memory, that logs nothing."

	| monitor |
	monitor := EpMonitor current.
	self deny: monitor isEnabled.
	self assert: monitor log entriesCount equals: 0.
	self assert: monitor log store writingFileReference fileSystem isMemoryFileSystem
]
