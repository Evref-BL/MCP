"
Abstract command for tool-catalog operations. Catalog commands receive the registry whose tools and effective exposure metadata they query.
"
Class {
	#name : 'MCPToolCatalogCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'toolRegistry'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPToolCatalogCommand class >> isAbstract [

	^ self == MCPToolCatalogCommand
]

{ #category : 'instance creation' }
MCPToolCatalogCommand class >> tool: aTool request: aRequest toolRegistry: aToolRegistry [

	^ self new
		  initializeTool: aTool request: aRequest;
		  toolRegistry: aToolRegistry;
		  yourself
]

{ #category : 'accessing' }
MCPToolCatalogCommand >> toolRegistry [

	^ toolRegistry
]

{ #category : 'accessing' }
MCPToolCatalogCommand >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry
]
