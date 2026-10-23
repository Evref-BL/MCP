"
MCP protocol structure for the suggestions completion/complete answers.

The spec caps a response at one hundred values, so a longer list is cut and hasMore says so while total keeps the real count.
"
Class {
	#name : 'MCPStructureCompletion',
	#superclass : 'Object',
	#instVars : [
		'values',
		'total',
		'hasMore'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureCompletion class >> maximumValues [

	^ 100
]

{ #category : 'instance creation' }
MCPStructureCompletion class >> values: aCollection [
	"Cut to the hundred the spec allows, keeping the real count so a client can say there are more."

	| all |
	all := aCollection asArray.
	^ self new
		  values: (all first: (self maximumValues min: all size));
		  total: all size;
		  hasMore: all size > self maximumValues;
		  yourself
]

{ #category : 'converting' }
MCPStructureCompletion >> asJRPCJSON [

	^ {
		  (#values -> self values asJRPCJSON).
		  (#total -> self total asJRPCJSON).
		  (#hasMore -> self hasMore asJRPCJSON) } asDictionary
]

{ #category : 'accessing' }
MCPStructureCompletion >> hasMore [

	^ hasMore
]

{ #category : 'accessing' }
MCPStructureCompletion >> hasMore: anObject [

	hasMore := anObject
]

{ #category : 'accessing' }
MCPStructureCompletion >> total [

	^ total
]

{ #category : 'accessing' }
MCPStructureCompletion >> total: anObject [

	total := anObject
]

{ #category : 'accessing' }
MCPStructureCompletion >> values [

	^ values
]

{ #category : 'accessing' }
MCPStructureCompletion >> values: anObject [

	values := anObject
]
