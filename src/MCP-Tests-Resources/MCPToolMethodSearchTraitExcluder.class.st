"
Fixture class that uses the method-search fixture trait without one of its methods, so class_get tests can check that an exclusion is reported.
"
Class {
	#name : 'MCPToolMethodSearchTraitExcluder',
	#superclass : 'Object',
	#traits : 'TMCPToolMethodSearchFixture - {#mcpTraitFixtureValue}',
	#classTraits : 'TMCPToolMethodSearchFixture classTrait - {#mcpTraitFixtureValue}',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}
