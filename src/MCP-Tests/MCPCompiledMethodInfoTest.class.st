"
Tests compiled-method metadata extraction.
"
Class {
	#name : 'MCPCompiledMethodInfoTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

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
	"The target is a committed fixture; this only rebuilds it where it belongs if something removed it."

	self hasTargetClass ifTrue: [ ^ self ].
	self withoutEpiceaDuring: [
			| builder |
			builder := Object << self targetClassName asSymbol.
			builder package: 'MCP-Tests-Resources'.
			builder slots: #(  ).
			builder install ]
]

{ #category : 'private' }
MCPCompiledMethodInfoTest >> extensionSelector [
	"Generated rather than committed: a test that rewrites a versioned fixture leaves its package modified, though the source it ends with is the source it started with."

	^ #generatedExtensionInfoTarget
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
MCPCompiledMethodInfoTest >> restoreFixtureMethods [

	self createTargetClass.
	self removeSelector: self instanceSelector from: self targetClass.
	self removeSelector: self classSelector from: self classTarget.
	self removeSelector: self extensionSelector from: self targetClass.
	self
		ensureMethodSource: 'infoTarget

	^ 1'
		protocol: 'tests'
		on: self targetClass.
	self
		ensureMethodSource: 'classInfoTarget

	^ 2'
		protocol: 'tests'
		on: self classTarget.
	self
		ensureMethodSource: 'generatedExtensionInfoTarget

	^ 3'
		protocol: self generatedExtensionProtocol
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

	^ MCPCompiledMethodInfoTestTarget name
]

{ #category : 'running' }
MCPCompiledMethodInfoTest >> tearDown [

	self restoreFixtureMethods.
	self removeSelector: self extensionSelector from: self targetClass.
	self removeGeneratedPackagesIfEmpty.
	super tearDown
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testBuildsInfoForExtensionMethod [

	| info |
	info := MCPCompiledMethodInfo fromMethod: self targetClass >> self extensionSelector.
	self assert: info className equals: self targetClassName.
	self assert: info selector equals: self extensionSelector asString.
	self deny: info classSide.
	self assert: info packageName equals: self generatedExtensionPackageName.
	self assert: info isExtension.
	self assert: info protocol equals: self generatedExtensionProtocol.
	self assert: (info source includesSubstring: self extensionSelector asString)
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testBuildsInfoForInstanceAndClassMethods [

	| classInfo instanceInfo |
	instanceInfo := MCPCompiledMethodInfo fromMethod: self targetClass >> self instanceSelector.
	classInfo := MCPCompiledMethodInfo fromMethod: self classTarget >> self classSelector.
	self assert: instanceInfo className equals: self targetClassName.
	self deny: instanceInfo classSide.
	self assert: instanceInfo selector equals: 'infoTarget'.
	self assert: instanceInfo protocol equals: 'tests'.
	self deny: instanceInfo isExtension.
	self assert: classInfo className equals: self targetClassName.
	self assert: classInfo classSide.
	self assert: classInfo selector equals: 'classInfoTarget'
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testRecordsNoTraitForAMethodTheClassDefinesItself [

	| info |
	info := MCPCompiledMethodInfo fromMethod: MCPToolMethodSearchTraitOverrider >> #mcpTraitFixtureValue.
	self assert: info traitName isNil.
	self deny: (info asDictionary includesKey: #trait)
]

{ #category : 'tests' }
MCPCompiledMethodInfoTest >> testRecordsTheTraitAMethodWasInstalledFrom [

	| info |
	info := MCPCompiledMethodInfo fromMethod: MCPToolMethodSearchTraitUser >> #mcpTraitFixtureValue.
	self assert: info traitName equals: TMCPToolMethodSearchFixture name asString.
	self assert: (info asDictionary at: #trait) equals: TMCPToolMethodSearchFixture name asString
]
