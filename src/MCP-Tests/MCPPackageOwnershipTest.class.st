"
Holds that loading MCP leaves every package owning the methods it had: a package that takes a method from another one when it loads leaves both marked modified on Pharo 10 and 11.
"
Class {
	#name : 'MCPPackageOwnershipTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPPackageOwnershipTest >> testNoPackageTakesAMethodATraitGivesItsClass [
	"A package that defines a method one of the class's traits gives it takes the method from the class's package when it loads. Pharo 10 and 11 then mark that package modified, and every package whose name begins it: a fresh load left MCP-IDE and MCP so, for a visitor method of Epicea's trait that a compatibility package defined. A method the class needs on every version belongs to the class's own package."

	| taken |
	taken := OrderedCollection new.
	self mcpPackageNames do: [ :name |
			(self packageOrganizer packageNamed: name) extensionMethods do: [ :method |
				(method methodClass traitComposition selectors includes: method selector) ifTrue: [ taken add: method printString ] ] ].
	self assertEmpty: taken
]
