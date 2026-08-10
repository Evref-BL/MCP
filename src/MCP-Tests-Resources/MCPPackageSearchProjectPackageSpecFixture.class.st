Class {
	#name : 'MCPPackageSearchProjectPackageSpecFixture',
	#superclass : 'Object',
	#instVars : [
		'name'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPPackageSearchProjectPackageSpecFixture class >> named: aName [

	^ self new
		  name: aName;
		  yourself
]

{ #category : 'accessing' }
MCPPackageSearchProjectPackageSpecFixture >> name [

	^ name
]

{ #category : 'accessing' }
MCPPackageSearchProjectPackageSpecFixture >> name: aString [

	name := aString
]
