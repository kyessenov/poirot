Poirot
========

A language designed to assist web developers in discovering potential security issues in the design and integration of web APIs. Poirot takes (1) a set of API views, each describing how a group of related APIs are used, (2) a set of API mappings, each specifying how independent APIs are to be integrated, and (3) a desired security property.  The tool then performs an end-to-end dataflow analysis to produce attack scenarios that demonstrate how the system may violate the property in presence of malicious actors on the Web. The tool leverages an extensible library of web-specific threat models to discover not only simple attacks that exploit a single design or security flaw, but also complex attacks that involve a combination of multiple vulnerabilities in the system.

