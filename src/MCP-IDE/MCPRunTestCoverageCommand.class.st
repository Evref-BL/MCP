"
The ordinary test runner with scoped method and sequence instrumentation around it.
"
Class {
	#name : 'MCPRunTestCoverageCommand',
	#superclass : 'MCPRunTestsCommand',
	#instVars : [
		'coverageScope',
		'includeCoveredMethods',
		'methodLimit'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

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

{ #category : 'accessing' }
MCPRunTestCoverageCommand >> methodLimit: anInteger [

	methodLimit := anInteger
]

{ #category : 'private' }
MCPRunTestCoverageCommand >> runSelectionsUntil: deadline [

	| result link |
	result := MCPTestCoverageResult new
		          methods: (coverageScope methods reject: [ :each | self shouldIgnoreMethod: each ]);
		          includeCoveredMethods: includeCoveredMethods;
		          methodLimit: methodLimit;
		          yourself.
	link := MetaLink new
		        metaObject: result executedNodes;
		        selector: #add:;
		        arguments: #( node );
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
