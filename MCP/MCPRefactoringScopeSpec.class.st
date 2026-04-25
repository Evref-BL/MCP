"
Parsed refactoring scope input shared by edit tools.
"
Class {
	#name : 'MCPRefactoringScopeSpec',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'hierarchyClassNames'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRefactoringScopeSpec class >> packageNames: packageNamesCollection classNames: classNamesCollection hierarchyClassNames: hierarchyClassNamesCollection [

	^ self new
		  initializePackageNames: packageNamesCollection
		  classNames: classNamesCollection
		  hierarchyClassNames: hierarchyClassNamesCollection
]

{ #category : 'converting' }
MCPRefactoringScopeSpec >> asDictionary [

	^ {
		  (#packageNames -> self packageNames).
		  (#classNames -> self classNames).
		  (#hierarchyClassNames -> self hierarchyClassNames) } asDictionary
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> classNames [

	^ classNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> hierarchyClassNames [

	^ hierarchyClassNames ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPRefactoringScopeSpec >> initializePackageNames: packageNamesCollection classNames: classNamesCollection hierarchyClassNames: hierarchyClassNamesCollection [

	packageNames := packageNamesCollection ifNil: [ #(  ) ].
	classNames := classNamesCollection ifNil: [ #(  ) ].
	hierarchyClassNames := hierarchyClassNamesCollection ifNil: [ #(  ) ].
	^ self
]

{ #category : 'testing' }
MCPRefactoringScopeSpec >> isDefaultImageScope [

	^ self packageNames isEmpty and: [
		  self classNames isEmpty and: [ self hierarchyClassNames isEmpty ] ]
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> scope [

	self isDefaultImageScope ifTrue: [ ^ 'image' ].
	(self packageNames isNotEmpty and: [
		 self classNames isEmpty and: [ self hierarchyClassNames isEmpty ] ])
		ifTrue: [ ^ 'packages' ].
	(self classNames isNotEmpty and: [
		 self packageNames isEmpty and: [ self hierarchyClassNames isEmpty ] ])
		ifTrue: [ ^ 'classes' ].
	(self hierarchyClassNames isNotEmpty and: [
		 self packageNames isEmpty and: [ self classNames isEmpty ] ])
		ifTrue: [ ^ 'hierarchy' ].
	^ 'custom'
]
