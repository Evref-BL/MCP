Class {
	#name : 'MCPRunTestCoverageCommandFailing',
	#superclass : 'MCPRunTestCoverageCommand',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRunTestCoverageCommandFailing >> runEachSelectionUntil: deadline [

	self error: 'Coverage runner fixture failure'
]
