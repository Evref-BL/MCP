"
Fixture class that defines selectors and protocols for method-search tests.
"
Class {
	#name : 'MCPToolMethodSearchTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'meta filtering' }
MCPToolMethodSearchTestTarget class >> classNeedleSelector [

	^ 'class needle'
]

{ #category : 'meta helpers' }
MCPToolMethodSearchTestTarget class >> classUtility [

	^ 'class utility'
]

{ #category : 'filtering' }
MCPToolMethodSearchTestTarget >> alphaNeedleSelector [

	^ 'needle alpha'
]

{ #category : 'helpers' }
MCPToolMethodSearchTestTarget >> betaHelper [

	^ 'beta helper'
]

{ #category : 'filtering' }
MCPToolMethodSearchTestTarget >> gammaUtility [

	^ 'gamma value'
]
