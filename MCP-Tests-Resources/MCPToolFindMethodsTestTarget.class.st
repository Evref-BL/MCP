Class {
	#name : 'MCPToolFindMethodsTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'meta filtering' }
MCPToolFindMethodsTestTarget class >> classNeedleSelector [

	^ 'class needle'
]

{ #category : 'meta helpers' }
MCPToolFindMethodsTestTarget class >> classUtility [

	^ 'class utility'
]

{ #category : 'filtering' }
MCPToolFindMethodsTestTarget >> alphaNeedleSelector [

	^ 'needle alpha'
]

{ #category : 'helpers' }
MCPToolFindMethodsTestTarget >> betaHelper [

	^ 'beta helper'
]

{ #category : 'filtering' }
MCPToolFindMethodsTestTarget >> gammaUtility [

	^ 'gamma value'
]
