"
The ordinary test runner with scoped method and sequence instrumentation around it.
"
Class {
	#name : 'MCPRunTestCoverageCommand',
	#superclass : 'MCPRunTestsCommand',
	#instVars : [
		'coverageScope',
		'includeCoveredMethods',
		'methodLimit',
		'leftOutMethodCount'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'accessing' }
MCPRunTestCoverageCommand class >> instrumentationPackageNames [
	"Pharo's own packages that a coverage link runs through. Instrumented, the link's own work passes through them again, and the image stops answering."

	^ #( 'Kernel' 'Collections' 'Reflectivity' 'AST' )
]

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> coverageScope [

	^ coverageScope
]

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> coverageScope: aScope [

	coverageScope := aScope
]

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> includeCoveredMethods: aBoolean [

	includeCoveredMethods := aBoolean
]

{ #category : 'private' }
MCPRunTestCoverageCommand >> isInstrumentationMethod: aMethod [
	"Whether aMethod is filed in a package a coverage link runs through, which is the method's own package: an extension a project adds to Object is its project's to measure."

	| name |
	name := aMethod package ifNil: [ ^ false ] ifNotNil: [ :package | package name ].
	^ self class instrumentationPackageNames anySatisfy: [ :each | name = each or: [ name beginsWith: each , '-' ] ]
]

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> methodLimit: anInteger [

	methodLimit := anInteger
]

{ #category : 'private' }
MCPRunTestCoverageCommand >> runSelectionsUntil: deadline [
	"The link runs at the base level only, so recording an entry, which sends to collections the scope may hold, records nothing more."

	| measured result link |
	measured := coverageScope methods reject: [ :each | self shouldIgnoreMethod: each ].
	leftOutMethodCount := measured count: [ :each | self isInstrumentationMethod: each ].
	result := MCPTestCoverageResult new
		          methods: (measured reject: [ :each | self isInstrumentationMethod: each ]);
		          includeCoveredMethods: includeCoveredMethods;
		          methodLimit: methodLimit;
		          yourself.
	link := MetaLink new
		        metaObject: result executedNodes;
		        selector: #add:;
		        arguments: #( node );
		        level: 0;
		        yourself.
	[
		result nodesToInstrument do: [ :each | each link: link ].
		result executedNodes removeAll.
		result finishWithTestResult: (super runSelectionsUntil: deadline) ] ensure: [ link uninstall ].
	^ result
]

{ #category : 'private' }
MCPRunTestCoverageCommand >> shouldIgnoreMethod: aMethod [

	^ aMethod methodClass instanceSide isTestCase or: [ aMethod isAbstract or: [ aMethod hasPragmaNamed: #ignoreForCoverage ] ]
]

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> warnings [
	"What the scope said, and the methods left out because measuring them would stop the image."

	(leftOutMethodCount ifNil: [ 0 ]) = 0 ifTrue: [ ^ coverageScope warnings ].
	^ coverageScope warnings
	  , { ('Did not measure {1} in Pharo''s {2} packages: coverage runs through them, and measuring them stops the image.' format: {
				   (leftOutMethodCount printString , (leftOutMethodCount = 1
					     ifTrue: [ ' method' ]
					     ifFalse: [ ' methods' ])).
				   (', ' join: self class instrumentationPackageNames) }) }
]
