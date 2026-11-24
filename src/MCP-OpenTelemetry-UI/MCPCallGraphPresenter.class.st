"
Spec presenter for the call graph of an MCP server: the successive calls its OpenTelemetry spans record, as an object-centric process model whose central object is the tool. It is the third inspector tab of a server, beside its dashboard and its observability, and is only there once MCP-OpenTelemetry is loaded.
"
Class {
	#name : 'MCPCallGraphPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'statusLabel'
	],
	#category : 'MCP-OpenTelemetry-UI',
	#package : 'MCP-OpenTelemetry-UI'
}

{ #category : 'layout' }
MCPCallGraphPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  borderWidth: 8;
		  add: statusLabel expand: false;
		  yourself
]

{ #category : 'initialization' }
MCPCallGraphPresenter >> initializePresenters [

	statusLabel := self newLabel.
	statusLabel label: 'Call graph: nothing to show yet.'
]
