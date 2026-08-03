Smalltalk globals
	at: #Iceberg
	ifPresent: [ :iceberg |
		iceberg remoteTypeSelector: #httpsUrl ].

#(
	AutomaticRewriting
	Deprecation
	BackwardCompatibility
) do: [ :className |
	Smalltalk globals
		at: className
		ifPresent: [ :rewritingClass |
			rewritingClass activateTransformations: false ] ].
