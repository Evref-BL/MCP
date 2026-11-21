"
Computes coverage from this run's method and sequence entries, independently of AST annotations used by other collectors.
"
Class {
	#name : 'MCPTestCoverageResult',
	#superclass : 'MCPResult',
	#instVars : [
		'testResult',
		'methodAsts',
		'sequenceNodes',
		'executedNodes',
		'includeCoveredMethods',
		'methodLimit'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'private' }
MCPTestCoverageResult >> addMethods: methods named: aKey to: data [

	| sorted |
	sorted := methods asArray sort: [ :left :right | left name <= right name ].
	data
		at: aKey
		put: ((sorted first: (methodLimit min: sorted size)) collect: [ :each | (MCPCompiledMethodInfo fromMethod: each) asDictionary ]).
	data at: (aKey , 'Truncated') asSymbol put: methods size > methodLimit
]

{ #category : 'converting' }
MCPTestCoverageResult >> asDictionary [

	^ testResult asDictionary
		  at: #coverage put: self coverageDictionary;
		  yourself
]

{ #category : 'converting' }
MCPTestCoverageResult >> coverageDictionary [

	| covered partial uncovered data coveredNodeCount |
	covered := methodAsts keys select: [ :each | executedNodes includes: (methodAsts at: each) ].
	partial := covered reject: [ :each |
		           (methodAsts at: each) allChildren allSatisfy: [ :node | node isSequence not or: [ executedNodes includes: node ] ] ].
	uncovered := methodAsts keys reject: [ :each | covered includes: each ].
	coveredNodeCount := sequenceNodes count: [ :each | executedNodes includes: each ].
	data := {
		        (#methodCount -> methodAsts size).
		        (#coveredMethodCount -> covered size).
		        (#fullyCoveredMethodCount -> (covered size - partial size)).
		        (#uncoveredMethodCount -> uncovered size).
		        (#partiallyCoveredMethodCount -> partial size).
		        (#nodeCount -> sequenceNodes size).
		        (#coveredNodeCount -> coveredNodeCount).
		        (#percentage -> (sequenceNodes ifEmpty: [ nil ] ifNotEmpty: [ 100.0 * coveredNodeCount / sequenceNodes size ])) }
		        asDictionary.
	self addMethods: uncovered named: #uncoveredMethods to: data.
	self addMethods: partial named: #partiallyCoveredMethods to: data.
	includeCoveredMethods ifTrue: [ self addMethods: covered named: #coveredMethods to: data ].
	^ data
]

{ #category : 'accessing' }
MCPTestCoverageResult >> executedNodes [

	^ executedNodes
]

{ #category : 'accessing' }
MCPTestCoverageResult >> finishWithTestResult: aResult [
	"The link keeps its original set, so uninstalling it cannot add to the result."

	testResult := aResult.
	executedNodes := executedNodes copy
]

{ #category : 'accessing' }
MCPTestCoverageResult >> includeCoveredMethods: aBoolean [

	includeCoveredMethods := aBoolean
]

{ #category : 'initialization' }
MCPTestCoverageResult >> initialize [

	super initialize.
	executedNodes := IdentitySet new
]

{ #category : 'accessing' }
MCPTestCoverageResult >> methodLimit: anInteger [

	methodLimit := anInteger
]

{ #category : 'initialization' }
MCPTestCoverageResult >> methods: methods [

	methodAsts := IdentityDictionary new.
	sequenceNodes := IdentitySet new.
	methods do: [ :each |
			| ast |
			ast := each ast.
			methodAsts at: each put: ast.
			ast nodesDo: [ :node | node isSequence ifTrue: [ sequenceNodes add: node ] ] ]
]

{ #category : 'accessing' }
MCPTestCoverageResult >> nodesToInstrument [

	^ methodAsts values , sequenceNodes asArray
]
