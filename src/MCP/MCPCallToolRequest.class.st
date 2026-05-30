"
Request object for dynamic tool invocation through tool_call.

It carries the catalog tool name and the nested argument dictionary that will be validated by the selected tool's own schema.
"
Class {
	#name : 'MCPCallToolRequest',
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
MCPCallToolRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  toolName: (aToolRequest stringArgumentNamed: 'toolName');
		  arguments:
			  (aToolRequest
				   argumentNamed: 'arguments'
				   ifAbsent: [ Dictionary new ]);
		  yourself
]

{ #category : 'accessing' }
MCPCallToolRequest >> arguments [

	^ arguments ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPCallToolRequest >> arguments: aDictionary [

	arguments := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPCallToolRequest >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPCallToolRequest >> toolName: aString [

	toolName := aString
]
