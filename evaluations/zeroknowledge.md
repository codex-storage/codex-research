Zero Knowledge Proofs
=====================

Zero knowledge proofs allow for a verifier to check that a prover knows a value,
without revealing that value.

Types
-----

Several types of non-interactive zero knowledge schemes exist. The most
well-known are zkSNARK and zkSTARK, which [come in several flavours][8].
Interestingly, the most performant is the somewhat older Groth16 scheme, with
very small proof size and verification time. Its downside is the requirement for
a trusted setup, and its [malleability][9]. Performing a trusted setup has
become easier through the [Perpetual Powers of Tau Ceremony][10].

A lesser-known type of zero knowledge scheme is [MPC-in-the-head][11]. This lets
a prover simulate a secure multiparty computation on a single computer, and uses
the communication between the simulated parties as proof. The [ZKBoo][13] scheme
for instance allows for fast generation and verification of proofs, but does not
lead to smaller proofs than zkSNARKs can provide.

Tooling
-------

[Zokrates][1] is a complete toolbox for specifiying and generating and verifying
zkSNARK proofs. It's written in Rust, has Javascript bindings, and can generate
Solidity code for verification. C bindings appear to be absent.

[libSNARK][2] and [libSTARK][3] are C++ libraries for zkSNARK and zkSTARK
proofs. libSNARK can be used as a backend for Zokrates.

[bellman][4] is a Rust libray for zkSNARK proofs. It can also be used as a
backend for Zokrates.

Iden3 created a suite of tools ([circom][5], [snarkjs][6], [rapidsnark][7]) for
zkSNARKs (Groth16 and PLONK). It is mostly Javascript, except for rapidsnark
which is writting in C++.

Nim tooling seems to be mostly absent.

Ethereum
--------

Ethereum has pre-compiled contracts [BN_ADD, BN_MUL and SNARKV][12] that reduce
the gas costs of zkSNARK verification. These are used by the Solidity code that
Zokrates produces.

[1]: https://zokrates.github.io
[2]: https://github.com/scipr-lab/libsnark
[3]: https://github.com/elibensasson/libSTARK
[4]: https://github.com/zkcrypto/bellman/
[5]: https://github.com/iden3/circom
[6]: https://github.com/iden3/snarkjs
[7]: https://github.com/iden3/rapidsnark
[8]: https://medium.com/coinmonks/comparing-general-purpose-zk-snarks-51ce124c60bd
[9]: https://zokrates.github.io/toolbox/proving_schemes.html#g16-malleability
[10]: https://medium.com/coinmonks/announcing-the-perpetual-powers-of-tau-ceremony-to-benefit-all-zk-snark-projects-c3da86af8377
[11]: https://yewtu.be/V8acfV8LJog
[12]: https://coders-errand.com/ethereum-support-for-zk-snarks/
[13]: https://www.usenix.org/conference/usenixsecurity16/technical-sessions/presentation/giacomelli