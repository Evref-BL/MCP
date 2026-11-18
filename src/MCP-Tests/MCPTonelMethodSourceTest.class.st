"
Tests how a method written as a Tonel file writes it is read back as a source method_compile compiles.
"
Class {
	#name : 'MCPTonelMethodSourceTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testACategoryLineAloneLeavesTheRestAsTheSource [
	"A category line above a selector line or a method's reference gives the protocol and leaves the rest as it is, header and all."

	| tonel |
	tonel := MCPTonelMethodSource fromString: '{ #category : ''accessing'' }
Foo >> bar
	^ 1'.
	self deny: tonel hasHeader.
	self assert: tonel category equals: 'accessing'.
	self assert: tonel source equals: 'Foo >> bar
	^ 1'
]

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testASourceThatCompilesAsWrittenIsNotTonel [
	"No method Pharo compiles begins with a category line or a class name followed by >>, so a method's own source, a block after its selector line included, is not read as Tonel. Neither is a method followed by more than blanks."

	#( 'bar ^ 1' 'bar [ ^ 1 ]' '"Foo >> bar [" bar ^ 1' '>> other ^ self' 'Foo >> bar [ ^ 1 ] baz' 'Foo >> bar [ ^ 1' ) do: [ :each |
		self assert: (MCPTonelMethodSource fromString: each) isNil description: each ]
]

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testBracketsInStringsAndCommentsStayInTheBody [

	self
		assert: (MCPTonelMethodSource fromString: 'Foo >> bar [
	"] [ in a comment"
	^ ''] ['' , #( $] ) printString
]') source
		equals: 'bar
	"] [ in a comment"
	^ ''] ['' , #( $] ) printString'
]

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testMethodTextsSplitsAPageOfSeveralMethods [
	"A page of several methods splits into each one's text, category line included, which reads back as that method. One method alone is not split."

	| texts |
	texts := MCPTonelMethodSource methodTextsIn: '{ #category : ''a'' }
Foo >> a [
	^ ''] ''
]

{ #category : ''b'' }
Foo class >> b [ ^ 2 ]
'.
	self assert: texts size equals: 2.
	self assert: (MCPTonelMethodSource fromString: texts first) category equals: 'a'.
	self assert: (MCPTonelMethodSource fromString: texts first) source equals: 'a
	^ ''] '''.
	self assert: (MCPTonelMethodSource fromString: texts second) classSide.
	self assert: (MCPTonelMethodSource methodTextsIn: texts first) isEmpty.
	self assert: (MCPTonelMethodSource methodTextsIn: 'a ^ 1') isEmpty
]

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testReadsTheCategoryOfEachTonelVersion [
	"Tonel v1 writes the category as a symbol, v2 and v3 as a string; each reads as the protocol's name."

	{ '{ #category : #accessing }'. '{ #category : ''accessing'' }'. '{ #category : #''accessing'' }' } do: [ :line |
			| tonel |
			tonel := MCPTonelMethodSource fromString: line , '
Foo >> bar [
	^ 1
]'.
			self assert: tonel category equals: 'accessing'.
			self assert: tonel source equals: 'bar
	^ 1' ]
]

{ #category : 'tests' }
MCPTonelMethodSourceTest >> testReadsTheHeader [
	"The header names the class and side, and its selector line, argument names included, begins the source."

	| tonel |
	tonel := MCPTonelMethodSource fromString: 'Foo class >> at: index put: value [

	^ index
]'.
	self assert: tonel hasHeader.
	self assert: tonel className equals: 'Foo'.
	self assert: tonel classSide.
	self assert: tonel header equals: 'Foo class >> at: index put: value'.
	self assert: tonel category isNil.
	self assert: tonel source equals: 'at: index put: value

	^ index'.
	tonel := MCPTonelMethodSource fromString: 'Foo>>+ other [ ^ other ]'.
	self deny: tonel classSide.
	self assert: tonel source equals: '+ other ^ other'
]
