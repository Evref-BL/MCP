"
Test double for an Iceberg working copy used by repository tool tests.
"
Class {
	#name : 'MCPTestRepositoryWorkingCopy',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'packageNames',
		'modifiedPackages'
	],
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPTestRepositoryWorkingCopy class >> packageNames: packageNameCollection modifiedPackages: modifiedPackageCollection [

	^ self new
		  packageNames: packageNameCollection;
		  modifiedPackages: modifiedPackageCollection;
		  yourself
]

{ #category : 'testing' }
MCPTestRepositoryWorkingCopy >> isModified [

	^ self modifiedPackages notEmpty
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> modifiedPackages [

	^ modifiedPackages ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> modifiedPackages: aCollection [

	modifiedPackages := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packageNames: aCollection [

	packageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> packages [

	^ #(  )
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> repository [

	^ repository
]

{ #category : 'accessing' }
MCPTestRepositoryWorkingCopy >> repository: aRepository [

	repository := aRepository
]
