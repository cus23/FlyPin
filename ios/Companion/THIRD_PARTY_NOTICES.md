# Third-party notices

## idevice

FlyPin Companion links the MIT-licensed `idevice` library maintained by Jackson Coxson.
The iOS static library and C header are fetched at build time from the immutable
StikDebug repository commit `7a80dfce28eeb501faca6498d1746949ac921e74`.
Both files are checked against their Git blob object IDs before linking:

- `idevice.h`: `2aef885909b7162cb92107e224390d766a4fd9bd`
- `libidevice_ffi.a`: `3fb7e2dbfdb9db3d47bd6364a435bbc10d5581f9`

Source project: https://github.com/jkcoxson/idevice
Pinned distribution source: https://github.com/StikDebug/StikDebug/tree/7a80dfce28eeb501faca6498d1746949ac921e74/StikDebug/idevice

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

## Apple Developer Disk Image assets

The Cryptex Developer Disk Image payloads are fetched from the immutable
`doronz88/DeveloperDiskImage` commit
`dcec53989fa57695c2b3d3e11c2585f4735b2fef` and verified against Git blob IDs
before use. These are Apple's developer support assets mirrored for
interoperability; they are not included in the app binary or source repository.
See https://github.com/doronz88/DeveloperDiskImage for the repository's legal notice.
