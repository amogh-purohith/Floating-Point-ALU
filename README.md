# fp-alu

A parameterized floating point arithmetic unit written in SystemVerilog, targeting IEEE-754-style half (16-bit), single (32-bit), and double (64-bit) precision through a shared, configurable core.

## Status

This project is under active development and is currently being redone from scratch. The module structure and interfaces below reflect the current design direction, but implementations are incomplete and subject to change. This is not yet usable as a drop-in FPU core.

## Architecture

```
fp_pkg.sv       - shared types and classification flags
fp_class.sv     - decodes sign/exponent/mantissa, classifies NaN/Inf/Zero/Subnormal/Normal
fp_add.sv       - floating point addition
fp_sub.sv       - floating point subtraction (built on fp_add)
fp_mul.sv       - floating point multiplication
fp_roundoff.sv  - rounding logic
fp_alu.sv       - top-level precision configuration and entry point
```

Each arithmetic module decodes its operands through `fp_class` into sign, exponent, mantissa, and classification flags, and returns the same flag set on output, so modules can be composed on a consistent interface.

## Supported precisions

- Half precision (16-bit)
- Single precision (32-bit)
- Double precision (64-bit)

Precision is set via a package-level parameter and the exponent/mantissa widths are derived from it, rather than maintaining separate modules per precision.

## Roadmap

- Redesign and reimplement core modules (in progress)
- Complete rounding logic in `fp_roundoff` and integrate it into `fp_add` and `fp_mul`
- Complete `fp_alu` top-level integration and opcode dispatch
- Division and square root modules
- Testbenches per module
- End-to-end exception flag handling (overflow, underflow, inexact)


