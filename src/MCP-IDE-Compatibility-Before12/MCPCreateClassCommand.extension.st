Extension { #name : 'MCPCreateClassCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPCreateClassCommand >> buildClass [
	"Before Pharo 12, a class is filed under a category that names its package and its tag together, and that names an existing package when one is a prefix of it. The package is registered first, so that the class lands in it, and the builder takes the names of the pools."

	| builder |
	self packageOrganizer ensurePackage: self packageName.
	builder := self superclass << self className asSymbol.
	builder package: self packageName.
	self tag ifNotNil: [ builder tag: self tag ].
	builder slots: self slots.
	self classSlots ifNotEmpty: [ builder classSlots: self classSlots ].
	self traits ifNotEmpty: [ builder traits: self resolvedTraits ].
	self sharedVariables ifNotEmpty: [ builder sharedVariables: self sharedVariables ].
	self sharedPools ifNotEmpty: [ builder sharedPools: (self resolvedSharedPools collect: [ :pool | pool name ]) ].
	self layout ifNotNil: [ :layoutName | builder layout: (self resolvedLayoutClassNamed: layoutName) ].
	^ builder install
]
