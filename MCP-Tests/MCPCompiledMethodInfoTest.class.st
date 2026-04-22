Class {
	#name : 'MCPCompiledMethodInfoTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCompiledMethodInfoTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> classSelector [

	^ #classInfoTarget
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> classTarget [

	^ (self classNamed: self targetClassName) classSide
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> createTargetClass [

	self hasTargetClass ifTrue: [ ^ self ].
	self withoutEpiceaDuring: [
		| builder |
		builder := Object << self targetClassName asSymbol.
		builder package: 'MCP-Tests'.
		builder tag: 'Internal'.
		builder slots: #(  ).
		builder install ]
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	self withoutEpiceaDuring: [
		aBehavior compile: aMethodSource classified: aProtocol ]
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> extensionSelector [

	^ #extensionInfoTarget
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> hasTargetClass [

	^ Smalltalk globals includesKey: self targetClassName asSymbol
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> instanceSelector [

	^ #infoTarget
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> removeSelector: aSelector from: aBehavior [

	self withoutEpiceaDuring: [
		(aBehavior includesSelector: aSelector) ifTrue: [
			aBehavior removeSelector: aSelector ] ]
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> restoreFixtureMethods [

	self createTargetClass.
	self removeSelector: self instanceSelector from: self targetClass.
	self removeSelector: self classSelector from: self classTarget.
	self removeSelector: self extensionSelector from: self targetClass.
	self
		ensureMethodSource: 'infoTarget ^ 1'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'classInfoTarget ^ 2'
		protocol: 'tests'
		on: self classTarget.
	self
		ensureMethodSource: 'extensionInfoTarget ^ 3'
		protocol: '*MCP-Tests-Resources-Extensions'
		on: self targetClass
]

{ #category : 'running' }
MCPCompiledMethodInfoTest >> setUp [

	super setUp.
	self restoreFixtureMethods
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> targetClass [

	^ self classNamed: self targetClassName
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> targetClassName [

	^ 'MCPCompiledMethodInfoTestTarget'
]

{ #category : 'running' }
MCPCompiledMethodInfoTest >> tearDown [

	self restoreFixtureMethods.
	super tearDown
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testBuildsInfoForExtensionMethod [

	| info |
	info := MCPCompiledMethodInfo fromCompiledMethod:
		        self targetClass >> self extensionSelector.
	self assert: info className equals: self targetClassName.
	self assert: info selector equals: 'extensionInfoTarget'.
	self assert: info side equals: 'instance'.
	self
		assert: info packageName
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: info isExtension.
	self assert: info protocol equals: '*MCP-Tests-Resources-Extensions'.
	self assert: (info source includesSubstring: 'extensionInfoTarget')
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testBuildsInfoForInstanceAndClassMethods [

	| classInfo instanceInfo |
	instanceInfo := MCPCompiledMethodInfo fromCompiledMethod:
		                self targetClass >> self instanceSelector.
	classInfo := MCPCompiledMethodInfo fromCompiledMethod:
		             self classTarget >> self classSelector.
	self assert: instanceInfo className equals: self targetClassName.
	self assert: instanceInfo side equals: 'instance'.
	self assert: instanceInfo selector equals: 'infoTarget'.
	self assert: instanceInfo protocol equals: 'tests'.
	self deny: instanceInfo isExtension.
	self assert: classInfo className equals: self targetClassName.
	self assert: classInfo side equals: 'class'.
	self assert: classInfo selector equals: 'classInfoTarget'
]
