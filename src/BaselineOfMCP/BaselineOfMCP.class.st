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
		baseline: 'PharoBackwardCompatibility' with: [ spec repository: 'github://jecisc/PharoBackwardCompatibility:master/src' ];
		baseline: 'JRPC' with: [
				spec
					repository: 'github://juliendelplanque/JRPC:v3.2.1/src';
					loads: #( 'Deployment' ) ];
		baseline: 'PCRE2' with: [
			spec
				repository: 'github://Gabriel-Darbord/pharo-pcre2:v1.0.1/src';
				loads: #( 'Core' ) ];
		baseline: 'OpenTelemetry' with: [
			spec
				repository: 'github://Gabriel-Darbord/opentelemetry-pharo:v1.1.0/src';
				loads: #( 'traces' 'metrics' 'logs' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'MCP' );
		group: 'UI' with: #( 'MCP-UI' );
		group: 'Telemetry' with: #( 'MCP-OpenTelemetry' );
		group: 'Tests' with: #( 'MCP-Tests-Resources' 'MCP-Tests-RunResources' 'MCP-Tests' 'MCP-Tests-Resources-Extensions' );
		group: 'UI Tests' with: #( 'MCP-UI-Tests' );
		group: 'Telemetry Tests' with: #( 'MCP-OpenTelemetry-Tests' );
		group: 'default' with: #( 'Core' 'UI' 'Tests' 'UI Tests' );
		group: 'all' with: #( 'default' 'Telemetry' 'Telemetry Tests' ).

	SystemVersion current major >= 13 ifTrue: [ spec group: 'Core' with: #( 'MCP' 'MCP-Compatibility-From13' ) ].
	SystemVersion current major >= 14 ifTrue: [
		spec group: 'Core' with: #( 'MCP' 'MCP-Compatibility-From13' 'MCP-Compatibility-From14' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"common"

	spec package: 'MCP' with: [ spec requires: #( 'PharoBackwardCompatibility' 'JRPC' 'PCRE2' ) ].
	spec package: 'MCP-UI' with: [ spec requires: #( 'MCP' ) ].
	spec package: 'MCP-OpenTelemetry' with: [ spec requires: #( 'MCP' 'OpenTelemetry' ) ].
	spec package: 'MCP-OpenTelemetry-Tests' with: [ spec requires: #( 'MCP-OpenTelemetry' ) ].
	spec package: 'MCP-Tests-Resources' with: [ spec requires: #( 'MCP' ) ].
	spec package: 'MCP-Tests-RunResources' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-Tests' with: [ spec requires: #( 'MCP' 'MCP-Tests-Resources' 'MCP-Tests-RunResources' ) ].
	spec package: 'MCP-Tests-Resources-Extensions' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-UI-Tests' with: [ spec requires: #( 'MCP-UI' 'MCP-Tests' ) ].

	SystemVersion current major >= 13 ifTrue: [ spec package: 'MCP-Compatibility-From13' with: [ spec requires: #( 'MCP' ) ] ].
	SystemVersion current major >= 14 ifTrue: [ spec package: 'MCP-Compatibility-From14' with: [ spec requires: #( 'MCP' ) ] ]
]
