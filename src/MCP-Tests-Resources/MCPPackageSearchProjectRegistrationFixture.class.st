Class {
	#name : 'MCPPackageSearchProjectRegistrationFixture',
	#superclass : 'Object',
	#instVars : [
		'projectName',
		'packageNames',
		'loadedInImage'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'instance creation' }
MCPPackageSearchProjectRegistrationFixture class >> projectName: aProjectName packageNames: somePackageNames loadedInImage: aBoolean [

	^ self new
		  projectName: aProjectName;
		  packageNames: somePackageNames;
		  loadedInImage: aBoolean;
		  yourself
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> loadedInImage [

	^ loadedInImage ifNil: [ false ]
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> loadedInImage: aBoolean [

	loadedInImage := aBoolean
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> packageNames: aCollection [

	packageNames := aCollection
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> packages [

	^ self packageNames collect: [ :eachName | MCPPackageSearchProjectPackageSpecFixture named: eachName ]
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> projectName [

	^ projectName
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> projectName: aString [

	projectName := aString
]

{ #category : 'accessing' }
MCPPackageSearchProjectRegistrationFixture >> projectVersion [

	^ self
]
