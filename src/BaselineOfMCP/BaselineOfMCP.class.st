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
				loads: #( 'Deployment' ) ];
		baseline: 'TinyLogger' with: [
			spec
				repository: 'github://jecisc/TinyLogger:v1.x.x/src';
				loads: #( 'Core' ) ];
		baseline: 'PCRE2' with: [
			spec
				repository: 'github://Gabriel-Darbord/pharo-pcre2:main/src';
				loads: #( 'Core' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'MCP' );
		group: 'UI' with: #( 'MCP-UI' );
		group: 'Tests' with: #( 'MCP-Tests-Resources' 'MCP-Tests-RunResources' 'MCP-Tests' 'MCP-Tests-Resources-Extensions' );
		group: 'UI Tests' with: #( 'MCP-UI-Tests' );
		group: 'default' with: #( 'Core' 'UI' 'Tests' 'UI Tests' )
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"common"

	spec package: 'MCP' with: [ spec requires: #( 'PharoCompatibility' 'JRPC' 'TinyLogger' 'PCRE2' ) ].
	spec package: 'MCP-UI' with: [ spec requires: #( 'MCP' ) ].
	spec package: 'MCP-Tests-Resources' with: [ spec requires: #( 'MCP' ) ].
	spec package: 'MCP-Tests-RunResources' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-Tests' with: [ spec requires: #( 'MCP' 'MCP-Tests-Resources' 'MCP-Tests-RunResources' ) ].
	spec package: 'MCP-Tests-Resources-Extensions' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-UI-Tests' with: [ spec requires: #( 'MCP-UI' 'MCP-Tests' ) ]
]
