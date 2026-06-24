"
Command that removes methods and returns removed method DTO dictionaries.
"
Class {
	#name : 'MCPRemoveMethodsCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPRemoveMethodsCommand >> execute [

	| behavior selectorSymbols warningMessage |
	selectorSymbols := self request selectors collect: #asSymbol.
	warningMessage := 'This bypasses sender checks and may leave broken senders.'.
	behavior := self tool
		behaviorNamed: self request className
		classSide: self request classSide.
	selectorSymbols do: [ :selector |
		behavior
			compiledMethodAt: selector
			ifAbsent: [
				MCPCommandError
					signalMissingMethodInClassName: self request className
					classSide: self request classSide
					selector: selector asString ] ].
	self tool forceRemoveSelectors: selectorSymbols from: behavior.
	^ MCPRemoveMethodsResult
		fromRequest: self request
		removedMethods: #(  )
		warningMessages: { warningMessage }
]
