"
Parsed refactoring scope input shared by edit tools.
"
Class {
	#name : 'MCPRefactoringScopeSpec',
	#superclass : 'Object',
	#instVars : [
		'scope',
		'packageNames',
		'classNames'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRefactoringScopeSpec class >> scope: aScope packageNames: packageNamesCollection classNames: classNamesCollection [

	^ self new
		  initializeScope: aScope
		  packageNames: packageNamesCollection
		  classNames: classNamesCollection
]

{ #category : 'converting' }
MCPRefactoringScopeSpec >> asDictionary [

	^ {
		  (#scope -> self scope).
		  (#packageNames -> self packageNames).
		  (#classNames -> self classNames) } asDictionary
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> classNames [

	^ classNames
]

{ #category : 'initialization' }
MCPRefactoringScopeSpec >> initializeScope: aScope packageNames: packageNamesCollection classNames: classNamesCollection [

	scope := aScope.
	packageNames := packageNamesCollection ifNil: [ #(  ) ].
	classNames := classNamesCollection ifNil: [ #(  ) ].
	^ self
]

{ #category : 'testing' }
MCPRefactoringScopeSpec >> isDefaultImageScope [

	^ scope = 'image' and: [
		  packageNames isEmpty and: [ classNames isEmpty ] ]
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> packageNames [

	^ packageNames
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> scope [

	^ scope
]
