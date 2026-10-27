"
Compact public result for a method update selected and executed by a method mutation tool.
"
Class {
	#name : 'MCPMethodAppliedChangeResult',
	#superclass : 'MCPAppliedChangeResult',
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'converting' }
MCPMethodAppliedChangeResult >> asDictionary [

	^ self changeResult asDictionary copy
]
