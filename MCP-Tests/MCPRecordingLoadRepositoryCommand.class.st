"
Load-repository command test double that routes Metacello creation through MCPRecordingLoadBaselineCommand.
"
Class {
	#name : 'MCPRecordingLoadRepositoryCommand',
	#superclass : 'MCPLoadRepositoryCommand',
	#category : 'MCP-Tests-Support',
	#package : 'MCP-Tests',
	#tag : 'Support'
}

{ #category : 'private - executing' }
MCPRecordingLoadRepositoryCommand >> baselineCommandClass [

	^ MCPRecordingLoadBaselineCommand
]
