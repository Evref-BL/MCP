"
Parse tree rewriter that applies its rules again to what they produced until a pass changes nothing.

A rule may take one step per pass, as the string concatenation rule absorbs one operand of a chain at a time, and stopping after the first pass leaves the code halfway, worse than both where it started and where the rule was going. I wrap the rewriter RBTransformationRule drives, answering the three messages it sends, so it still builds the changes and still refuses a rewrite that makes a method call itself.

Each pass parses the previous pass's source again in the method's class, since the rules' conditions read bindings and the method's class, which a tree assembled from replacement patterns does not carry. A rewrite still matching after passLimit passes reproduces its own match, and is refused rather than applied.
"
Class {
	#name : 'MCPSettlingRewriter',
	#superclass : 'Object',
	#instVars : [
		'rewriter',
		'tree'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPSettlingRewriter class >> on: aRewriter [

	^ self new setRewriter: aRewriter
]

{ #category : 'accessing' }
MCPSettlingRewriter >> canMatchMethod: aMethod [

	^ rewriter canMatchMethod: aMethod
]

{ #category : 'rewriting' }
MCPSettlingRewriter >> executeTree: aMethodNode [
	"Answer whether the rules changed aMethodNode, having applied them again to each result until a pass changed nothing."

	| methodClass passes |
	tree := aMethodNode.
	(rewriter executeTree: aMethodNode) ifFalse: [ ^ false ].
	methodClass := aMethodNode methodClass.
	passes := 1.
	[
		tree := rewriter tree.
		rewriter executeTree: (methodClass compiler
				 source: tree newSource;
				 parse) ] whileTrue: [
			passes := passes + 1.
			passes > self passLimit ifTrue: [ self signalUnsettledIn: methodClass selector: aMethodNode selector ] ].
	^ true
]

{ #category : 'accessing' }
MCPSettlingRewriter >> passLimit [

	^ 100
]

{ #category : 'initialization' }
MCPSettlingRewriter >> setRewriter: aRewriter [

	rewriter := aRewriter
]

{ #category : 'rewriting' }
MCPSettlingRewriter >> signalUnsettledIn: aClass selector: aSelector [

	| method |
	method := String streamContents: [ :stream | stream << aClass name << '>>' << aSelector ].
	MCPCommandError
		signalErrorCode: #RewriteDoesNotSettle
		message: (String streamContents: [ :stream |
					 stream << 'The rewrite of ' << method << ' still matches after ' << self passLimit asString
					 << ' passes, so it reproduces its own match. Nothing was applied.' ])
		details: {
				(#method -> method).
				(#passes -> self passLimit) } asDictionary
]

{ #category : 'accessing' }
MCPSettlingRewriter >> tree [
	"The tree the last pass that changed anything produced."

	^ tree
]
