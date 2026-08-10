Class {
	#name : 'MCPPackageScopeQueryTestDouble',
	#superclass : 'MCPPackageScopeQuery',
	#instVars : [
		'projectRegistrations'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPPackageScopeQueryTestDouble >> projectRegistrations [

	^ projectRegistrations ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPPackageScopeQueryTestDouble >> projectRegistrations: aCollection [

	projectRegistrations := aCollection
]
