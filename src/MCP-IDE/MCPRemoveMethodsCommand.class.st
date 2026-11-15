"
Command that removes methods and returns removed method DTO dictionaries.
"
Class {
	#name : 'MCPRemoveMethodsCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPRemoveMethodsCommand >> execute [
	"Senders do not stop a removal. Once the methods are gone, the answer warns of the sends they left without a method."

	| behavior selectorSymbols |
	selectorSymbols := self request selectors collect: #asSymbol.
	behavior := self tool behaviorNamed: self request className classSide: self request classSide.
	selectorSymbols do: [ :selector |
			behavior compiledMethodAt: selector ifAbsent: [ MCPCommandError signalMissingMethod: selector asString in: behavior ].
			self tool signalTraitOriginBeforeRemoving: selector in: behavior ].
	self tool forceRemoveSelectors: selectorSymbols from: behavior.
	^ MCPRemoveMethodsResult
		  fromRequest: self request
		  removedMethods: #(  )
		  warningMessages: (self tool warningsForSendsLeftByRemoving: selectorSymbols from: behavior)
]
