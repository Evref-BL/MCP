"
Compact public result for a method update selected and executed by a method mutation tool.
"
Class {
	#name : 'MCPMethodAppliedChangeResult',
	#superclass : 'MCPAppliedChangeResult',
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'converting' }
MCPMethodAppliedChangeResult >> asDictionary [

	^ self changeResult asDictionary copy
]
