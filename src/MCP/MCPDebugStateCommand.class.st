Class {
	#name : 'MCPDebugStateCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPDebugStateCommand >> execute [

	| record state warnings |
	record := self sessionRecordWithMatchingState.
	state := (MCPDebugStateInfo fromRecord: record request: request)
		         asDictionary.
	warnings := state at: #warnings ifAbsent: [ #(  ) ].
	^ MCPDebugToolResult
		  okSummary: 'Debug state captured for ' , record sessionId , '.'
		  data: state
		  warnings: warnings
]
