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
		import: 'JRPC'.
	spec
		baseline: 'TinyLogger'
		with: [ spec repository: 'github://jecisc/TinyLogger:v1.x.x/src' ].
	spec baseline: 'Mocketry' with: [
		spec
			repository: 'github://dionisiydk/Mocketry:v7.0.2';
			loads: #( 'Core' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"common"

	spec package: 'MCP' with: [ spec requires: #( 'JRPC' 'TinyLogger' ) ].
	spec package: 'MCP-Spec' with: [ spec requires: #( 'MCP' ) ].
	spec
		package: 'MCP-Tests-Resources'
		with: [ spec requires: #( 'MCP' ) ].
	spec
		package: 'MCP-Tests'
		with: [ spec requires: #( 'MCP' 'MCP-Tests-Resources'
		   'Mocketry' ) ].
	spec
		package: 'MCP-Tests-Resources-Extensions'
		with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec
		package: 'MCP-Spec-Tests'
		with: [ spec requires: #( 'MCP-Spec' ) ]
]
