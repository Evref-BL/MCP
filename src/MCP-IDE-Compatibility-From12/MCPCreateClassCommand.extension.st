Extension { #name : 'MCPCreateClassCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPCreateClassCommand >> buildClass [

	| builder createdClass |
	builder := self superclass << self className asSymbol.
	builder package: self packageName.
	self tag ifNotNil: [ builder tag: self tag ].
	builder slots: self slots.
	self classSlots ifNotEmpty: [ builder classSlots: self classSlots ].
	self traits ifNotEmpty: [ builder traits: self resolvedTraits ].
	self sharedVariables ifNotEmpty: [ builder sharedVariables: self sharedVariables ].
	self sharedPools ifNotEmpty: [ builder sharedPools: self resolvedSharedPools ].
	self layout ifNotNil: [ :layoutName | builder layout: (self resolvedLayoutClassNamed: layoutName) ].
	createdClass := builder install.
	^ createdClass
]
