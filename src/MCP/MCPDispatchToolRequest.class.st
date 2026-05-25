Class {
	#name : 'MCPDispatchToolRequest',
	#superclass : 'Object',
	#instVars : [
		'toolName',
		'arguments'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDispatchToolRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  toolName: (aToolRequest stringArgumentNamed: 'toolName');
		  arguments:
			  (aToolRequest
				   argumentNamed: 'arguments'
				   ifAbsent: [ Dictionary new ]);
		  yourself
]

{ #category : 'accessing' }
MCPDispatchToolRequest >> arguments [

	^ arguments ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPDispatchToolRequest >> arguments: aDictionary [

	arguments := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPDispatchToolRequest >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPDispatchToolRequest >> toolName: aString [

	toolName := aString
]
