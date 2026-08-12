"
Renraku rule that warns when code filters a collection only to test whether the result is empty.

Use quantified collection messages such as anySatisfy:, noneSatisfy:, or allSatisfy: when the intent is an existence or universality check.
"
Class {
	#name : 'MCPFilteredEmptinessRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-Critiques',
	#package : 'MCP',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPFilteredEmptinessRule class >> rationale [

	^ 'Use anySatisfy:, noneSatisfy:, or allSatisfy: when filtering only to test emptiness.'
]

{ #category : 'accessing' }
MCPFilteredEmptinessRule class >> ruleName [

	^ 'Use quantified collection tests'
]

{ #category : 'initialization' }
MCPFilteredEmptinessRule >> initialize [

	super initialize.
	self
		replace: '(`@collection select: `@block) isEmpty' with: '`@collection noneSatisfy: `@block';
		replace: '(`@collection select: `@block) notEmpty' with: '`@collection anySatisfy: `@block';
		replace: '(`@collection reject: `@block) isEmpty' with: '`@collection allSatisfy: `@block';
		replace: '(`@collection reject: `@block) notEmpty' with: '(`@collection allSatisfy: `@block) not'
]
