"
Parsed input for debug_search.

It carries at most a filter. There is nothing to address: the debuggers a person has open are found again on every call, so no reference to one has to survive between calls.
"
Class {
	#name : 'MCPDebugSearchRequest',
	#superclass : 'Object',
	#instVars : [
		'query'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugSearchRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  query: (aRequest stringArgumentNamed: 'query');
		  yourself
]

{ #category : 'testing' }
MCPDebugSearchRequest >> matches: aString [

	query ifNil: [ ^ true ].
	^ aString asString asLowercase includesSubstring: query asLowercase
]

{ #category : 'accessing' }
MCPDebugSearchRequest >> query [

	^ query
]

{ #category : 'accessing' }
MCPDebugSearchRequest >> query: aString [

	query := aString
]
