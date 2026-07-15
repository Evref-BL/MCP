"
Tests the public package groups defined by BaselineOfMCP.
"
Class {
	#name : 'BaselineOfMCPTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Baseline',
	#package : 'MCP-Tests',
	#tag : 'Baseline'
}

{ #category : 'tests' }
BaselineOfMCPTest >> testGroupsSeparateCoreAndUITests [

	| spec |
	spec := MCPRecordingBaselineSpec new.
	BaselineOfMCP new defineGroups: spec.
	self assert: spec groups equals: {
			('Core' -> #( 'MCP' )).
			('UI' -> #( 'MCP-UI' )).
			('Tests' -> #( 'MCP-Tests-Resources' 'MCP-Tests' 'MCP-Tests-Resources-Extensions' )).
			('UI Tests' -> #( 'MCP-UI-Tests' )).
			('default' -> #( 'Core' 'UI' )) } asDictionary
]
