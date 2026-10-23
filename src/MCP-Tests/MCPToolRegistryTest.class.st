"
Tests that a discovering tool registry tracks the tool classes present in the image.

A registry outlives the classes it found, so loading or removing tool classes in a running image must not leave it answering a surface that no longer exists.
"
Class {
	#name : 'MCPToolRegistryTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPToolRegistryTest >> createProbeToolClass [
	"A tool class outside the MCP package that asks to be auto-registered, so discovery sees it without touching the shipped surface."

	| probeClass |
	probeClass := self
		              createClassNamed: self probeToolClassName
		              superclassName: #MCPTool
		              slots: #(  )
		              classSlots: #(  ).
	self ensureMethodSource: 'shouldAutoRegister

	^ true' protocol: 'testing' on: probeClass class.
	self ensureMethodSource: 'toolName

	^ ''registry_probe_tool''' protocol: 'metadata' on: probeClass class.
	self ensureMethodSource: 'groupName

	^ ''registry-probes''' protocol: 'metadata' on: probeClass class.
	self ensureMethodSource: 'title

	^ ''Registry Probe Tool''' protocol: 'metadata' on: probeClass.
	self ensureMethodSource: 'description

	^ ''Test fixture for tool class discovery.''' protocol: 'metadata' on: probeClass.
	self
		ensureMethodSource: 'shouldRecordObservability

	^ false'
		protocol: 'testing'
		on: probeClass.
	self ensureMethodSource: 'buildInputSchema

	^ MCPStructureInputSchema new
		  type: ''object'';
		  properties: #(  );
		  required: #(  );
		  additionalProperties: false;
		  yourself' protocol: 'metadata' on: probeClass.
	self ensureMethodSource: 'executeWithRequest: aRequest

	^ self successResultText: ''Probe executed.'' data: Dictionary new' protocol: 'executing' on: probeClass.
	^ probeClass
]

{ #category : 'private' }
MCPToolRegistryTest >> probeToolClassName [

	^ #MCPRegistryProbeTool
]

{ #category : 'private' }
MCPToolRegistryTest >> probeToolName [

	^ 'registry_probe_tool'
]

{ #category : 'private' }
MCPToolRegistryTest >> removeProbeToolClass [

	self removeClassNamed: self probeToolClassName
]

{ #category : 'running' }
MCPToolRegistryTest >> tearDown [

	self removeProbeToolClass.
	super tearDown
]

{ #category : 'tests' }
MCPToolRegistryTest >> testCuratedRegistryIgnoresNewToolClasses [
	"A registry built with #empty holds exactly what was registered into it. Profiles pin a surface that way, so discovery must not widen it."

	| registry |
	registry := MCPToolRegistry empty.
	registry registerToolClass: MCPExternalTestTool.
	self createProbeToolClass.
	self assert: registry publicToolNames asArray equals: (Array with: MCPExternalTestTool toolName)
]

{ #category : 'tests' }
MCPToolRegistryTest >> testDiscoveringRegistryDropsRemovedToolClasses [

	| registry |
	self createProbeToolClass.
	registry := MCPToolRegistry default.
	self assert: (registry publicToolNames includes: self probeToolName).
	self removeProbeToolClass.
	self deny: (registry publicToolNames includes: self probeToolName).
	self assert: (registry toolNamed: self probeToolName ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
MCPToolRegistryTest >> testDiscoveringRegistryPicksUpNewToolClasses [
	"The registry used to answer its startup surface until someone reset it by hand."

	| registry |
	registry := MCPToolRegistry default.
	self deny: (registry publicToolNames includes: self probeToolName).
	self createProbeToolClass.
	self assert: (registry publicToolNames includes: self probeToolName).
	self assert: (registry toolNamed: self probeToolName ifAbsent: [ nil ]) isNotNil
]

{ #category : 'tests' }
MCPToolRegistryTest >> testHandRegisteredToolsSurviveRediscovery [

	| registry |
	registry := MCPToolRegistry default.
	registry registerToolClass: MCPExternalTestTool.
	self createProbeToolClass.
	self assert: (registry publicToolNames includes: MCPExternalTestTool toolName).
	self assert: (registry publicToolNames includes: self probeToolName)
]

{ #category : 'tests' }
MCPToolRegistryTest >> testServerAnswersNewToolClassesWithoutAManualReset [
	"The cost this removes: tool_call answering 'No MCP tool named X' for a class the image already has."

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp staticToolNames: { self probeToolName }.
	self createProbeToolClass.
	self assert: ((mcp rpcToolsList at: #tools) collect: [ :each | each at: #name ]) asArray equals: { self probeToolName }
]
