"
Tests that the YAML a result is written with says what a plain line cannot: the type of a scalar, the length of a list, and where a value ends.
"
Class {
	#name : 'MCPYamlWriterTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}
{ #category : 'tests' }
MCPYamlWriterTest >> testListsSayHowManyTheyHold [
	"A comma-joined line cannot tell a list of two from one string containing a comma, nor a list of one from a scalar."

	self assert: (self yamlFor: { (#a -> #( 'x' 'y' )) } asDictionary) equals: 'a: [x, y]'.
	self assert: (self yamlFor: { (#a -> #( 'x' )) } asDictionary) equals: 'a: [x]'.
	self assert: (self yamlFor: { (#a -> #(  )) } asDictionary) equals: 'a: []'.
	self assert: (self yamlFor: { (#a -> 'x, y') } asDictionary) equals: 'a: x, y'
]

{ #category : 'tests' }
MCPYamlWriterTest >> testNestedStructuresIndentAndKeepSiblings [
	"A nested map must not end the map that holds it, and a list of maps takes a block entry each. The expectations are joined rather than written as literals, because method source stores its own lines with CR."

	| nested |
	nested := {
		          (#first -> { (#inner -> 1) } asDictionary).
		          (#second -> 2) } asDictionary.
	self assert: (self yamlFor: nested) equals: (String lf join: #( 'first:' '  inner: 1' 'second: 2' )).
	self
		assert: (self yamlFor: { (#items -> {
					  { (#a -> 1) } asDictionary.
					  { (#a -> 2) } asDictionary }) } asDictionary)
		equals: (String lf join: #( 'items:' '- a: 1' '- a: 2' ))
]

{ #category : 'tests' }
MCPYamlWriterTest >> testQuotesOnlyWhatWouldBeMisread [

	self assert: (self yamlFor: { (#a -> 'Class name.') } asDictionary) equals: 'a: Class name.'.
	self
		assert: (self yamlFor: { (#a -> 'Debugger id: debug_search.') } asDictionary)
		equals: 'a: "Debugger id: debug_search."'.
	self assert: (self yamlFor: { (#a -> '') } asDictionary) equals: 'a: ""'.
	self assert: (self yamlFor: { (#a -> '*Package-Name') } asDictionary) equals: 'a: "*Package-Name"'.
	self
		assert: (self yamlFor: { (#a -> 'two
lines') } asDictionary)
		equals: 'a: "two\nlines"'
]

{ #category : 'tests' }
MCPYamlWriterTest >> testScalarsKeepTheirType [
	"A line format writes 25 and '25' the same way, and so loses which one it had."

	self assert: (self yamlFor: { (#a -> 25) } asDictionary) equals: 'a: 25'.
	self assert: (self yamlFor: { (#a -> '25') } asDictionary) equals: 'a: "25"'.
	self assert: (self yamlFor: { (#a -> true) } asDictionary) equals: 'a: true'.
	self assert: (self yamlFor: { (#a -> 'true') } asDictionary) equals: 'a: "true"'.
	self assert: (self yamlFor: { (#a -> nil) } asDictionary) equals: 'a: null'
]

{ #category : 'private' }
MCPYamlWriterTest >> yamlFor: anObject [

	^ MCPYamlWriter yamlFor: anObject indent: ''
]

