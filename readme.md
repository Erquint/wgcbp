## WireGuard config batch processor

Utility script for automated batch processing of WireGuard-compliant configs to align them to user-specified standard, split them per clients with their own specified arguments and enrich the configs with additional parameters, such as to qualify for AmneziaWG-compliant advanced features.  
It uses a specification file of own format that the user configures to their preference and need.  
No input file is altered. Output files are created in subdirectories per client and packaged in `.tar.gz` containers alongside.  

## Usage

Supply a specification file and a directory containing WireGuard configs as follows…  

```shell
ruby main.rb <SPEC_FILE> <CONFIGS_DIR>
```

## Specification file format

Client-specific argument overrides are defined in the former half of the specification file and output parameter ordering along parameter identifier casing is defined after the `[Client:All]` keyword.  
A mock specification file `mock_spec.ini` is provided as example. Be sure to check it out and maybe that'll give you a better idea than the explanation contained in the next section of this readme.  
The specification file is for the user to configure — typically one per service provider account. It is not limited to parameters present in the mock example and neither is any particular parameter required. The only mandatory parts are at least one client with some definitions, the `[Client:All]` delimiter and some sectioned parameter identifiers ordered after it.  

### Client Definitions

Client definitions are sequenced between the beginning of the file and the reserved `[Client:All]` keyword delimiter.  
Each client section begins with a namespaced section identifier, such as `[Client:HomePC]` and/or `[Client:VacationiPhone]`.  
All subsequent lines until the next `[Client:*]` define that client's overrides.  
Reserved keyword `[Client:All]` marks the end of clients definition and begins output order specification.  
Within a client section, further INI subsections follow: normally `[Interface]` and `[Peer]` as typically found in WireGuard configs.  
This part of the specification file is semantic, parsed for data, not for format.  

### Parameter Order Specification

After `[Client:All]`, each line specifies the process that drives output config writing and resembles a comprehensive config file with sections and parameters but devoid of arguments.  
Order of entries and letter casing are preserved exactly.  
Section headers and blank lines are copied verbatim.  
Parameter identifiers are reflected in output as the same parameter with an argument taken from client specification and — if not found there — from input config being batched.  
If the argument for a parameter is not specified anywhere in the pair of config-client — the parameter is skipped and is not reflected in the output config.  

## Operation in detail

For each permutation of client defined and WireGuard config ending in `.conf` found in `CONFIGS_DIR`, the script will parse the config values, override them with specified client's values from `SPEC_FILE`, then write a new config to a clint-specific subdirectory of `CONFIGS_DIR` in format specified in the `SPEC_FILE`.  
To be clear in other words: arguments defined in client specification take overriding priority.  
All contents of input configs before the first section header are copied over as they are. There are often service provider comments there.  
Every comma will always be printed to configs with a trailing space: `, `.  
When supported provider-specific filenames are matched — they will be simplified in output written. In absence of a match — filenames are replicated up to the length limit.  
Filenames of permuted configs will always be clamped to 32 stem characters and will not include client identifier.  
Path of every written file will be printed to the terminal. No changes are made to input files.  
The internal handling of parameter identifiers is case-insensitive. You may mix and match casing as you please. The order spec section after `[Client:All]` defines exact identifiers printed in output.  

## Coverage

This script has been tested with WG and AWG configs, but fundamentally it is just a batch INI processor, which could be adapted for newer standards without requiring updates.  
No testing was performed on configs with multiple `[Peer]` sections present. The likely output for such is combination of all into one.  
There's not a ton of user error handling in this script, just the sensible fundamentals. Otherwise: garbage in — garbage out.  
For this project in particular, effort was made against providing user with customizable options outside of core necessity. This may change in the future.  
Currently only AirVPN filename pattern is recognized for simplification. It is hardcoded, but easily extensible and modifiable in code. Filenames of other naming conventions are just used as is until perhaps more patterns are added to the script in the future or the supported provider changes their convention and thus breaks present support.  

## Requirements

Tested to work on CRuby v3.2.2 runtime.  
No external gems used, just the bundled stdlib.  
