"
Load-repository command test double that routes Metacello creation through MCPRecordingLoadBaselineCommand.
"
Class {
	#name : 'MCPRecordingLoadRepositoryCommand',
	#superclass : 'MCPLoadRepositoryCommand',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private - executing' }
MCPRecordingLoadRepositoryCommand >> baselineCommandClass [

	^ MCPRecordingLoadBaselineCommand
]
