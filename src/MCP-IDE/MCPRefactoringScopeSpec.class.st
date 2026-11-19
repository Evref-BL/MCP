"
Parsed refactoring scope input shared by mutation tools.
"
Class {
	#name : 'MCPRefactoringScopeSpec',
	#superclass : 'Object',
	#instVars : [
		'packageNames',
		'classNames',
		'hierarchyClassNames'
	],
	#category : 'MCP-IDE-Specs',
	#package : 'MCP-IDE',
	#tag : 'Specs'
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
	"The scope as the call gave it, under the keys the schema gives them, since answers repeat it."

	^ {
		  (#packages -> self packageNames).
		  (#classes -> self classNames).
		  (#hierarchyOf -> self hierarchyClassNames) } asDictionary
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
	hierarchyClassNames := hierarchyClassNamesCollection ifNil: [ #(  ) ]
]

{ #category : 'testing' }
MCPRefactoringScopeSpec >> isDefaultImageScope [

	^ self packageNames isEmpty and: [ self classNames isEmpty and: [ self hierarchyClassNames isEmpty ] ]
]

{ #category : 'accessing' }
MCPRefactoringScopeSpec >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]
