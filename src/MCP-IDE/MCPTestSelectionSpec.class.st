"
One selection test_run and test_coverage_run run: a package, a test class, or one test method of a class, by the names the call gave.

It resolves those names in the image, and names itself back as test_run takes it, which is how a timeout lists what is left to run.
"
Class {
	#name : 'MCPTestSelectionSpec',
	#superclass : 'Object',
	#instVars : [
		'packageName',
		'className',
		'testMethodName',
		'testClass'
	],
	#category : 'MCP-IDE-Specs',
	#package : 'MCP-IDE',
	#tag : 'Specs'
}

{ #category : 'instance creation' }
MCPTestSelectionSpec class >> className: aClassName [

	^ self className: aClassName testMethodName: nil
]

{ #category : 'instance creation' }
MCPTestSelectionSpec class >> className: aClassName testMethodName: aTestMethodName [

	^ self new initializePackageName: nil className: aClassName testMethodName: aTestMethodName
]

{ #category : 'instance creation' }
MCPTestSelectionSpec class >> packageName: aPackageName [

	^ self new initializePackageName: aPackageName className: nil testMethodName: nil
]

{ #category : 'accessing' }
MCPTestSelectionSpec >> className [

	^ className
]

{ #category : 'printing' }
MCPTestSelectionSpec >> displayName [
	"The selection as test_run takes it: a package or a class by its name, a method as Class>>#selector."

	self isPackageSelection ifTrue: [ ^ packageName ].
	^ testMethodName
		  ifNil: [ className ]
		  ifNotNil: [ :methodName | String streamContents: [ :stream | stream << className << '>>#' << methodName ] ]
]

{ #category : 'testing' }
MCPTestSelectionSpec >> hasTestMethod [

	^ testMethodName isNotNil
]

{ #category : 'initialization' }
MCPTestSelectionSpec >> initializePackageName: aPackageName className: aClassName testMethodName: aTestMethodName [

	packageName := aPackageName.
	className := aClassName.
	testMethodName := aTestMethodName
]

{ #category : 'testing' }
MCPTestSelectionSpec >> isPackageSelection [

	^ packageName isNotNil
]

{ #category : 'accessing' }
MCPTestSelectionSpec >> packageName [

	^ packageName
]

{ #category : 'printing' }
MCPTestSelectionSpec >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayName;
		nextPutAll: ')'
]

{ #category : 'resolving' }
MCPTestSelectionSpec >> resolvedName [
	"The selection as a refusal and a selection without tests name it: a package by its name, a class or a method by the name of the class it resolves to."

	self isPackageSelection ifTrue: [ ^ packageName ].
	^ String streamContents: [ :stream |
			  stream << self testClass name.
			  testMethodName ifNotNil: [ :selector | stream << '>>#' << selector ] ]
]

{ #category : 'resolving' }
MCPTestSelectionSpec >> testClass [
	"The class a class or method selection names, on its instance side, refused in the lookup's words when it names none. It is looked up the first time it is asked, before anything runs, and kept: the run uses the class its selection was checked against, and its own lookups stay out of the coverage it measures."

	^ testClass ifNil: [ testClass := MCPImageLookup classNamed: className ]
]

{ #category : 'accessing' }
MCPTestSelectionSpec >> testMethodName [

	^ testMethodName
]
