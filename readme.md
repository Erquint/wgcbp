## WireGuard config batch processor

Utility for automated batch processing of WireGuard-compliant configs to align them to user-specified standard, split them per clients with their own specified arguments and enrich the configs with addiional parameters, such as to qualify for AmneziaWG-compliant advanced features.
It uses a specification file of own format that the user configures to their preference and need.
No input file is altered. Output files are created in subdirectories per client and packaged in `.tar.gz` containers alongside.

## Usage

Supply a spec file and a directory containing WireGuard configs as follows…

```
ruby main.rb <SPEC_FILE> <CONFIGS_DIR>
```

## Specification file format

Client-specific argument overrides are defined in the former half of the specification file and output parameter ordering along parameter identifier casing is defined after the `[Client:All]` keyword.
A mock specification file `mock_spec.ini` is provided as example. Be sure to check it out.

### Client Definitions

Client definitions are sequenced between the beginning of the file and the reserved `[Client:All]` keyword delimeter.
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

## Operation

For each permutation of client defined and WireGuard config ending in `.conf` found in `CONFIGS_DIR`, the script will parse the config values, override them with specified client's values from `SPEC_FILE`, then write a new config to a clint-specific subdirectory of `CONFIGS_DIR` in format specified in the `SPEC_FILE`.
To be clear in other words: arguments defined in client specification take overriding priority.
Path of every written file will be printed to the terminal.
All contents of input configs before the first section header are copied over as is. There are often service provider comments there.
Every comma will always be printed with a space following: `, `.
Filenames of permuted configs will always be clamped to 32 stem characters and will not include client identifier.
The internal handling of parameters is case-insensitive. You may mix and match casing as you please. The order spec section after `[Client:All]` defines how they will be printed in output.

## Coverage

This script has been tested with WG and AWG configs, but fundamentally it is just a batch INI processor, which could be adapted for newer standards without requiring updates.
No testing was performed on configs with multiple `[Peer]` sections present. The likely output for such is combination of all into one.

## Requirements

- CRuby runtime. Tested on v3.2.2.
- No external gems, just stdlib.
