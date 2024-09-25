# libscetool

- scetool (C) 2011-2013 by [naehrwert](https://github.com/naehrwert)
- NP local license handling (C) 2012 by flatz
- Library conversion + patches (C) 2023-2024 by [Lyris](https://github.com/Beyley/)

## Compilation

Install Zig 0.14.0-dev.1632+d83a3f174

- `zig build -Dtarget=[target triple] -Doptimize=ReleaseSmall` target triple can be things like `x86_64-windows` or `x86-macos` or `aarch64-linux-gnu` or any combination, or you can omit the target to build for your native platform

## Packaging

- `zig build package`

## Setup

- Keyfile: `/data/keys`.
- Loader curves (7744 bytes): `/data/ldr_curves`.
- VSH curves (360 bytes): `/data/vsh_curves`.
- IDPS as binary file: `/data/idps`
- act.dat: `/data/act.dat`
- RIF files: `/rifs/*:*.rif`
- RAP files: `/raps/*:*.rap`

## Keyfile Format

```
[keyname]
type={SELF, RVK, PKG, SPP, OTHER}
revision={00, ..., 18, 8000}
version={..., 0001000000000000, ...}
self_type={LV0, LV1, LV2, APP, ISO, LDR, UNK_7, NPDRM}
key=...
erk=...
riv=...
pub=...
priv=...
ctype=...
```

## Keyset Example

```
[metldr]
type=SELF
revision=00
self_type=LDR
erk=0000000000000000000000000000000000000000000000000000000000000000
riv=00000000000000000000000000000000
pub=00000000000000000000000000000000000000000000000000000000000000000000000000000000
priv=000000000000000000000000000000000000000000
ctype=00
```

## NPDRM Key(set) Names

- Title ID OMAC1 key: `[NP_tid]`
- Control info OMAC1 key: `[NP_ci]`
- Free klicensee: `[NP_klic_free]`
- klicensee key: `[NP_klic_key]`
- IDPS constant: `[NP_idps_const]`
- rif key: `[NP_rif_key]`
- Footer signature ECDSA keyset: `[NP_sig]`

## Override Keyset

 It should be a single hex-string consisting of:
 32 bytes (Key) 16 bytes (IV) 40 bytes (Pub) 21 bytes (Priv) 1 byte (CType).

## Version History

### Version 0.2.9

- Plaintext sections will now take less space in metadata header keys array.
- Added option to specifiy a template SELF to take configuration values from.
- Added option to override the keyset used for en-/decryption.
- Fixed NP application types.
- [Firmware Version] will now be written to control info only.
- [Application Version] will now be written to application info only.

### Version 0.2.8 (intermediate release)

- Fixed minor bugs where scetool would crash.
- Added SPP parsing.
- Decrypting RVK/SPP will now write header+data to file.

### Version 0.2.7

- Added local NP license handling.
- Added option to override klicensee.
- Added option to disable section skipping (in SELF generation).

### Version 0.2.5

- Added option to use provided metadata info for decryption.
- "PS3" path environment variable will now be searched for keys/ldr_curves/vsh_curves too.

### Version 0.2.4

- Added option to display raw values.
- Moved factory Auth-IDs to \<public build\> (as they are on ps3devwiki now).

### Version 0.2.2

- Added options to override control/capability flags (32 bytes each).
- Fixed where a false keyset would crash scetool when decrypting a file.
- Some source level changes and optimizations.

### Version 0.2.1

- zlib is required to use scetool.
- 'sdk_type' was changed to 'revision' in data/keys.
