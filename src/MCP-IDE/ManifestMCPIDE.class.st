"
The image tools an MCP client works through: classes, methods, packages, tests, critiques, repositories, change history and debugging. Loading this package is all it takes for the server to catalog them.
"
Class {
	#name : 'ManifestMCPIDE',
	#superclass : 'PackageManifest',
	#category : 'MCP-IDE-Manifest',
	#package : 'MCP-IDE',
	#tag : 'Manifest'
}

{ #category : 'rules' }
ManifestMCPIDE class >> agentRuleClasses [
	"The critique rules this package brings. They are off in Renraku, so the browser and Iceberg do not run them; MCP's tools do."

	^ (self ruleClasses reject: [ :each | each isAbstract ]) asArray sort: [ :left :right | left name <= right name ]
]

{ #category : 'formatting' }
ManifestMCPIDE class >> formatter [

	^ ManifestBaselineOfMCP formatter
]

{ #category : 'class initialization' }
ManifestMCPIDE class >> initialize [
	"Renraku keeps whether a rule is on once it has read it, so an image that loaded an earlier MCP would keep these rules on. Forgetting it lets each read its default again."

	self ruleClasses do: [ :each | each enabled: nil ]
]

{ #category : 'rules' }
ManifestMCPIDE class >> ruleClasses [
	"The critique rules this package brings, abstract ones included: Renraku runs whatever it finds visible."

	^ self package definedClasses select: [ :each | each inheritsFrom: ReAbstractRule ]
]
