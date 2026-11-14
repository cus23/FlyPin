# Third-party notices

## idevice

FlyPin Companion links the MIT-licensed `idevice` library maintained by Jackson Coxson.
The iOS static library and its C header are fetched at build time from the StikDebug
repository at the immutable commit
`c5b23e228249e384cf3e034fd379bf8b9abb76e2`, then checked against pinned SHA-256
digests before linking. FlyPin does not include the downloaded binary in source control.

Source project: https://github.com/jkcoxson/idevice
Pinned distribution source: https://github.com/StephenDev0/StikDebug/tree/c5b23e228249e384cf3e034fd379bf8b9abb76e2/StikDebug/idevice

SHA-256:
- `idevice.h`: `864b8c5b15cce6280c7645b49980a626b3a44aeabfdaf30124881b9b2a47a5c4`
- `libidevice_ffi.a`: `6524066d54ef23e00d46445c04dfc694e180196d54119d718f68434fa225be35`

MIT License notice:

Copyright 2026 Jackson Coxson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Developer Support files

Personalized Developer Disk Image, trust cache, and build manifest files are not
bundled. Their source, device-build compatibility, provenance, and integrity must
be verified before they are used. A successful app build does not prove that an
image can be mounted on a physical iPhone.
