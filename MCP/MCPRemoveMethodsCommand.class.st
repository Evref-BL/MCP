"
Command that removes methods and returns removed method DTO dictionaries.
"
Class {
	#name : 'MCPRemoveMethodsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRemoveMethodsCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPRemoveMethodsCommand >> execute [

	| behavior removedMethods selectorSymbols warningMessage |
	selectorSymbols := request selectors collect: #asSymbol.
	warningMessage := 'This bypasses sender checks and may leave broken senders.'.
	behavior := tool
		            behaviorNamed: request className
		            classSide: request classSide.
	removedMethods := selectorSymbols collect: [ :selector |
		                  | compiledMethod |
		                  compiledMethod := behavior
			                                    compiledMethodAt: selector
			                                    ifAbsent: [
				                                    MCPCommandError
					                                    signalMissingMethodInClassName:
					                                    request className
					                                    classSide: request classSide
					                                    selector: selector asString ].
		                  tool dataForMethod: compiledMethod ].
	tool forceRemoveSelectors: selectorSymbols from: behavior.
	^ MCPRemoveMethodsResult
		  fromRequest: request
		  removedMethods: removedMethods
		  warningMessages: { warningMessage }
]

{ #category : 'initialization' }
MCPRemoveMethodsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPRemoveMethodsCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPRemoveMethodsCommand >> tool [

	^ tool
]
