"
A servers presenter whose new servers export no observability, so a test can create one without writing into the image directory.
"
Class {
	#name : 'MCPServersPresenterTestDouble',
	#superclass : 'MCPServersPresenter',
	#category : 'MCP-UI-Tests-Server',
	#package : 'MCP-UI-Tests',
	#tag : 'Server'
}

{ #category : 'actions' }
MCPServersPresenterTestDouble >> newServerOnPort: aPortNumber [

	^ (super newServerOnPort: aPortNumber)
		  observabilityExportDirectory: nil;
		  yourself
]
