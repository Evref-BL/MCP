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
	self defineGroups: spec.
	self defineCompatibilityPackages: spec
]

{ #category : 'baselines' }
BaselineOfMCP >> defineCompatibilityPackages: spec [
	"Each loads right after the package it extends, in that package's group."

	| major |
	major := SystemVersion current major.
	major < 12
		ifTrue: [
				spec
					package: 'MCP-Compatibility-Before12' with: [ spec requires: #( 'MCP' ) ];
					group: 'Core' with: #( 'MCP-Compatibility-Before12' );
					package: 'MCP-IDE-Compatibility-Before12' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-Before12' ) ]
		ifFalse: [
				spec
					package: 'MCP-Compatibility-From12' with: [ spec requires: #( 'MCP' ) ];
					group: 'Core' with: #( 'MCP-Compatibility-From12' );
					package: 'MCP-IDE-Compatibility-From12' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-From12' ) ].
	major < 13
		ifTrue: [
				spec
					package: 'MCP-Compatibility-Before13' with: [ spec requires: #( 'MCP' ) ];
					group: 'Core' with: #( 'MCP-Compatibility-Before13' );
					package: 'MCP-IDE-Compatibility-Before13' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-Before13' );
					package: 'MCP-UI-Compatibility-Before13' with: [ spec requires: #( 'MCP-UI' ) ];
					group: 'UI' with: #( 'MCP-UI-Compatibility-Before13' ) ]
		ifFalse: [
				spec
					package: 'MCP-Compatibility-From13' with: [ spec requires: #( 'MCP' ) ];
					group: 'Core' with: #( 'MCP-Compatibility-From13' );
					package: 'MCP-IDE-Compatibility-From13' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-From13' ) ].
	major < 14
		ifTrue: [
				spec
					package: 'MCP-IDE-Compatibility-Before14' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-Before14' ) ]
		ifFalse: [
				spec
					package: 'MCP-IDE-Compatibility-From14' with: [ spec requires: #( 'MCP-IDE' ) ];
					group: 'IDE' with: #( 'MCP-IDE-Compatibility-From14' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineDependencies: spec [

	spec
		baseline: 'PharoBackwardCompatibility' with: [ spec repository: 'github://jecisc/PharoBackwardCompatibility:v1.x.x/src' ];
		baseline: 'JRPC' with: [
				spec
					repository: 'github://Evref-BL/JRPC:v4.0.1/src';
					loads: #( 'Server-Deployment' 'HTTP-Transport' ) ];
		baseline: 'PCRE2' with: [
			spec
				repository: 'github://Gabriel-Darbord/pharo-pcre2:v2.2.0/src';
				loads: #( 'PharoMinimal' 'UnicodeProperties' ) ];
		baseline: 'OpenTelemetry' with: [
			spec
				repository: 'github://Gabriel-Darbord/opentelemetry-pharo:v1.3.0/src';
				loads: #( 'traces' 'metrics' 'logs' 'autoconfigure' ) ]
]

{ #category : 'baselines' }
BaselineOfMCP >> defineGroups: spec [

	spec
		group: 'Core' with: #( 'MCP' );
		group: 'IDE' with: #( 'MCP-IDE' );
		group: 'UI' with: #( 'MCP-UI' );
		group: 'Telemetry' with: #( 'MCP-OpenTelemetry' );
		group: 'Tests' with: #( 'MCP-Tests' );
		group: 'UI Tests' with: #( 'MCP-UI-Tests' );
		group: 'Telemetry Tests' with: #( 'MCP-OpenTelemetry-Tests' );
		group: 'default' with: #( 'Core' 'IDE' 'UI' );
		group: 'all' with: #( 'default' 'Telemetry' 'Tests' 'UI Tests' 'Telemetry Tests' )
]

{ #category : 'baselines' }
BaselineOfMCP >> definePackages: spec [
	"Each package requires the group of the layer under it, which brings that layer's compatibility packages too."

	spec package: 'MCP' with: [ spec requires: #( 'PharoBackwardCompatibility' 'JRPC' ) ].
	spec package: 'MCP-IDE' with: [ spec requires: #( 'Core' 'PCRE2' ) ].
	spec package: 'MCP-UI' with: [ spec requires: #( 'Core' ) ].
	spec package: 'MCP-OpenTelemetry' with: [ spec requires: #( 'Core' 'OpenTelemetry' ) ].
	spec package: 'MCP-OpenTelemetry-Tests' with: [ spec requires: #( 'MCP-OpenTelemetry' ) ].
	spec package: 'MCP-Tests-Resources' with: [ spec requires: #( 'IDE' ) ].
	spec package: 'MCP-Tests-RunResources' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-Tests-Resources-Extensions' with: [ spec requires: #( 'MCP-Tests-Resources' ) ].
	spec package: 'MCP-Tests' with: [ spec requires: #( 'MCP-Tests-RunResources' 'MCP-Tests-Resources-Extensions' ) ].
	spec package: 'MCP-UI-Tests' with: [ spec requires: #( 'UI' 'MCP-Tests' ) ]
]
