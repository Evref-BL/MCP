"
Load-repository command test double that routes Metacello creation through MCPRecordingLoadBaselineCommand.
"
Class {
	#name : 'MCPRecordingLoadRepositoryCommand',
	#superclass : 'MCPLoadRepositoryCommand',
	#category : 'MCP-Tests-Resources-Support',
	#package : 'MCP-Tests-Resources',
	#tag : 'Support'
}

{ #category : 'private - executing' }
MCPRecordingLoadRepositoryCommand >> baselineCommandClass [

	^ MCPRecordingLoadBaselineCommand
]
