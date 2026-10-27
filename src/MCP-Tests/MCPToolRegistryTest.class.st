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
	"A tool class outside the MCP packages, with nothing but the metadata any tool has. Loading it is the whole opt-in, so discovery sees it without touching the shipped surface."

	| probeClass |
	probeClass := self
		              createClassNamed: self probeToolClassName
		              superclassName: #MCPTool
		              slots: #(  )
		              classSlots: #(  ).
	self
		ensureMethodSource: 'toolName

	^ ''registry_probe_tool'''
		protocol: 'metadata'
		on: probeClass class.
	self
		ensureMethodSource: 'groupName

	^ ''registry-probes'''
		protocol: 'metadata'
		on: probeClass class.
	self
		ensureMethodSource: 'title

	^ ''Registry Probe Tool'''
		protocol: 'metadata'
		on: probeClass.
	self
		ensureMethodSource: 'description

	^ ''Test fixture for tool class discovery.'''
		protocol: 'metadata'
		on: probeClass.
	self
		ensureMethodSource: 'shouldRecordObservability

	^ false'
		protocol: 'testing'
		on: probeClass.
	self
		ensureMethodSource: 'buildInputSchema

	^ MCPStructureInputSchema new
		  type: ''object'';
		  properties: #(  );
		  required: #(  );
		  additionalProperties: false;
		  yourself'
		protocol: 'metadata'
		on: probeClass.
	self
		ensureMethodSource: 'executeWithRequest: aRequest

	^ self successResultText: ''Probe executed.'' data: Dictionary new'
		protocol: 'executing'
		on: probeClass.
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
MCPToolRegistryTest >> testARediscoveryThatFailedPartwayIsTriedAgain [
	"Recording what was discovered before filing it left a failed pass claiming classes it had never filed, after which every later pass answered that nothing had changed."

	| registry |
	registry := MCPFailingKeyRegistryTestDouble default.
	self createProbeToolClass.
	registry failNextFiling.
	self should: [ registry toolNames ] raise: Error.
	self assert: (registry toolNames includes: self probeToolName)
]

{ #category : 'tests' }
MCPToolRegistryTest >> testAToolClassIsNotDiscoveredUntilItCanNameItself [
	"Building a tool in a live image compiles the class before its methods. A catalog that tried to file it in between would raise for every tool, including the ones compiling the rest of it."

	| probeClass registry |
	probeClass := self
		              createClassNamed: self probeToolClassName
		              superclassName: #MCPTool
		              slots: #(  )
		              classSlots: #(  ).
	self deny: probeClass shouldAutoRegister.
	registry := MCPToolRegistry default.
	self deny: (registry toolNames includes: self probeToolName).
	self
		ensureMethodSource: 'toolName

	^ ''registry_probe_tool'''
		protocol: 'metadata'
		on: probeClass class.
	self assert: probeClass shouldAutoRegister
]

{ #category : 'tests' }
MCPToolRegistryTest >> testCuratedRegistryIgnoresNewToolClasses [
	"A registry built with #empty holds exactly what was registered into it. Profiles pin a surface that way, so discovery must not widen it."

	| registry |
	registry := MCPToolRegistry empty.
	registry addTool: MCPExternalTestTool.
	self createProbeToolClass.
	self assert: registry toolNames asArray equals: (Array with: MCPExternalTestTool toolName)
]

{ #category : 'tests' }
MCPToolRegistryTest >> testDeliberatelyRemovedToolsStayRemoved [
	"Rediscovery takes in what appeared and drops what vanished. If it rebuilt instead, a tool removed on purpose would come back the next time any tool class was loaded."

	| registry |
	registry := MCPToolRegistry default.
	self assert: (registry includesToolNamed: 'image_evaluate').
	registry removeToolNamed: 'image_evaluate'.
	self createProbeToolClass.
	self assert: (registry includesToolNamed: self probeToolName).
	self deny: (registry includesToolNamed: 'image_evaluate')
]

{ #category : 'tests' }
MCPToolRegistryTest >> testDiscoveringRegistryDropsRemovedToolClasses [

	| registry |
	self createProbeToolClass.
	registry := MCPToolRegistry default.
	self assert: (registry toolNames includes: self probeToolName).
	self removeProbeToolClass.
	self deny: (registry toolNames includes: self probeToolName).
	self assert: (registry toolNamed: self probeToolName ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
MCPToolRegistryTest >> testDiscoveringRegistryPicksUpNewToolClasses [
	"The registry used to answer its startup surface until someone reset it by hand."

	| registry |
	registry := MCPToolRegistry default.
	self deny: (registry toolNames includes: self probeToolName).
	self createProbeToolClass.
	self assert: (registry toolNames includes: self probeToolName).
	self assert: (registry toolNamed: self probeToolName ifAbsent: [ nil ]) isNotNil
]

{ #category : 'tests' }
MCPToolRegistryTest >> testHandRegisteredToolsSurviveRediscovery [

	| registry |
	registry := MCPToolRegistry default.
	registry addTool: MCPExternalTestTool.
	self createProbeToolClass.
	self assert: (registry toolNames includes: MCPExternalTestTool toolName).
	self assert: (registry toolNames includes: self probeToolName)
]

{ #category : 'tests' }
MCPToolRegistryTest >> testServerAnswersNewToolClassesWithoutAManualReset [
	"The cost this removes: tool_call answering 'No MCP tool named X' for a class the image already has."

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	self deny: (mcp toolRegistry toolNames includes: self probeToolName).
	self createProbeToolClass.
	mcp advertiseTools: { self probeToolName }.
	self assert: ((mcp rpcToolsList at: #tools) collect: [ :each | each at: #name ]) asArray equals: { self probeToolName }
]
