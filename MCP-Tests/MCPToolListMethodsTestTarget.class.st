Class {
	#name : 'MCPToolListMethodsTestTarget',
	#superclass : 'Object',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'meta filtering' }
MCPToolListMethodsTestTarget class >> classNeedleSelector [

	^ 'class needle'
]

{ #category : 'meta helpers' }
MCPToolListMethodsTestTarget class >> classUtility [

	^ 'class utility'
]

{ #category : 'filtering' }
MCPToolListMethodsTestTarget >> alphaNeedleSelector [

	^ 'needle alpha'
]

{ #category : 'helpers' }
MCPToolListMethodsTestTarget >> betaHelper [

	^ 'beta helper'
]

{ #category : 'filtering' }
MCPToolListMethodsTestTarget >> gammaUtility [

	^ 'gamma value'
]
