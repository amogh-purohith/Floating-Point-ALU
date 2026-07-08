
# fp-alu

Parametric IEEE-754 floating point arithmetic unit written in SystemVerilog. Supports half (16-bit), single (32-bit), and double (64-bit) precision through a single configurable parameter.

## Status

Under active development. Core modules are implemented and being verified against the IEEE-754 specification; interfaces and internal rounding logic are still subject to change. Not yet recommended for production use.

## Overview

The design centers on a shared package (`fp_pkg`) that derives all format-dependent constants (exponent width, mantissa width, bias) from a single `PRECISION` parameter. Arithmetic modules import this package rather than duplicating format logic, and a top-level `fp_alu` module exposes a single instantiation point for consumers.

```systemverilog
fp_alu #(.PRECISION(32)) fpu (
    .a(operand_a),
    .b(operand_b),
    .op(fp_opcode),
    .result(fp_result),
    .flags(fp_result_flags)
);
```

## Module Status

| Module        | Description                                         | Status      |
|---------------|------------------------------------------------------|-------------|
| `fp_pkg`      | Shared format parameters and flag types               | In progress |
| `fp_class`    | Operand classification (NaN, Inf, zero, subnormal)     | Implemented |
| `fp_add`      | Addition                                              | In progress |
| `fp_sub`      | Subtraction                                           | In progress |
| `fp_mul`      | Multiplication                                        | In progress |
| `fp_roundoff` | Shared rounding logic (guard/round/sticky)             | In progress |
| `fp_alu`      | Top-level dispatch module                              | In progress |
| `fp_div`      | Division                                              | Not started |
| `fp_sqrt`     | Square root                                           | Not started |
| Pipelining    | Multi-stage timing closure                             | Planned     |
| FMA           | Fused multiply-add                                    | Planned     |

## Supported Formats

| Format | Total Width | Exponent | Mantissa |
|--------|-------------|----------|----------|
| Half   | 16          | 5        | 10       |
| Single | 32          | 8        | 23       |
| Double | 64          | 11       | 52       |

## Build / Compile Order

`fp_pkg.sv` must be compiled before any module that imports it.

```
fp_pkg.sv
fp_class.sv
fp_roundoff.sv
fp_add.sv
fp_sub.sv
fp_mul.sv
fp_alu.sv
```

## Usage

Clone the repository and add the source files to your project's file list in the order above.

```bash
git clone https://github.com/<username>/fp-alu.git
```

Instantiate `fp_alu` with the desired `PRECISION` and connect operand, opcode, result, and flag signals from your own design.

## Roadmap

- Complete rounding logic (round-to-nearest-even via guard/round/sticky bits)
- Full exception flag support (invalid, overflow, underflow, inexact)
- Opcode-based dispatch in `fp_alu`
- Directed and randomized verification against IEEE-754 test vectors
- Division and square root
- Pipelined implementation
- Fused multiply-add

## Contributing

Issues and corrections are welcome, particularly around IEEE-754 correctness in rounding and normalization.

## License

See [LICENSE](LICENSE).
```
