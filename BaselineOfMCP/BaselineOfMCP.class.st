Class {
	#name : 'BaselineOfMCP',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfMCP',
	#package : 'BaselineOfMCP'
}

{ #category : 'baselines' }
BaselineOfMCP >> baseline: spec [

	<baseline>
	self defineDependencies: spec.
	self definePackages: spec.
	self defineGroups: spec
]

{ #category : 'baselines' }
BaselineOfMCP >> defineDependencies: spec [

	spec
		baseline: 'JRPC' with: [
			spec
				repository: 'github://juliendelplanque/JRPC:v3.2.1/src';
				loads: #( 'Deployment' ) ];
		import: 'JRPC'
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"common"

	spec package: 'MCP' with: [ spec requires: #( 'JRPC' ) ].
	spec package: 'MCP-Spec' with: [ spec requires: #( 'MCP' ) ].
	spec package: 'MCP-Tests' with: [ spec requires: #( 'MCP' ) ].
	spec
		package: 'MCP-Tests-Extensions'
		with: [ spec requires: #( 'MCP-Tests' ) ]
]
