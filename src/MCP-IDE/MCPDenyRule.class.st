"
Renraku rule that warns when a test asserts a negation instead of denying it.

deny: says the expectation is false in the selector, where it is read first, rather than in a not at the end of the argument. Only a receiver that understands deny: is rewritten, since Object answers assert: and nothing else.
"
Class {
	#name : 'MCPDenyRule',
	#superclass : 'MCPMethodStyleRule',
	#category : 'MCP-IDE-Critiques',
	#package : 'MCP-IDE',
	#tag : 'Critiques'
}

{ #category : 'accessing' }
MCPDenyRule class >> rationale [

	^ 'Deny a condition instead of asserting its negation, and assert it instead of denying its negation.'
]

{ #category : 'accessing' }
MCPDenyRule class >> ruleName [

	^ 'Use deny: for a negated assertion'
]

{ #category : 'initialization' }
MCPDenyRule >> initialize [

	super initialize.
	self
		replace: '`@asserter `{ :node | MCPMethodStyleRule canSend: #deny: to: node } assert: `@condition not'
		with: '`@asserter deny: `@condition';
		replace:
			'`@asserter `{ :node | MCPMethodStyleRule canSend: #deny:description: to: node } assert: `@condition not description: `@description'
		with: '`@asserter deny: `@condition description: `@description';
		replace: '`@asserter deny: `@condition not' with: '`@asserter assert: `@condition';
		replace: '`@asserter deny: `@condition not description: `@description'
		with: '`@asserter assert: `@condition description: `@description'
]
