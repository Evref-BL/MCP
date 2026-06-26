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
		baseline: 'PharoCompatibility' with: [
				spec
					repository: 'github://Evref-BL/PharoCompatibility:main/src';
					loads: #( 'Pharo13Surface' ) ];
		baseline: 'JRPC' with: [
			spec
				repository: 'github://juliendelplanque/JRPC:v3.2.1/src';
				loads: #( 'Deployment' ) ].
	spec baseline: 'TinyLogger' with: [
			spec
				repository: 'github://jecisc/TinyLogger:v1.x.x/src';
				loads: #( 'Core' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'MCP' 'MCP-Spec' );
		group: 'Tests'
		with:
			#( 'MCP-Tests-Resources' 'MCP-Tests' 'MCP-Tests-Resources-Extensions'
			   'MCP-Spec-Tests' )
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"common"

	spec
		package: 'MCP'
		with: [
		spec requires: #( 'PharoCompatibility' 'JRPC' 'TinyLogger' ) ].
	spec package: 'MCP-Spec' with: [ spec requires: #( 'MCP' ) ].
	spec
		package: 'MCP-Tests-Resources'
		with: [ spec requires: #( 'MCP' ) ].
	spec
		package: 'MCP-Tests'
		with: [ spec requires: #( 'MCP' 'MCP-Tests-Resources' ) ].
	spec
		package: 'MCP-Tests-Resources-Extensions'
		with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec
		package: 'MCP-Spec-Tests'
		with: [ spec requires: #( 'MCP-Spec' 'MCP-Tests' ) ]
]
