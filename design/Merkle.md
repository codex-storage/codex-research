
Merkle tree API proposal (WIP draft)
------------------------------------

Let's collect the possible problems and solutions with constructing Merkle trees.

See [section "Final proposal"](#Final-proposal) at the bottom for the concrete 
version we decided to implement.

### Vocabulary

A Merkle tree, built on a hash function `H`, produces a Merkle root of type `T`. 
This is usually the same type as the output of the hash function. Some examples:

- SHA1: `T` is 160 bits
- SHA256: `T` is 256 bits
- Poseidon: `T` is one (or a few) finite field element(s)

The hash function `H` can also have different types `S` of inputs. For example:

- SHA1 / SHA256 / SHA3: `S` is an arbitrary sequence of bits
- some less-conforming implementation of these could take a sequence of bytes instead
- Poseidon: `S` is a sequence of finite field elements
- Poseidon compression function: at most `t-1` field elements (in our case `t=3`, so 
  that's two field elements)
- A naive Merkle tree implementation could for example accept only a power-of-two 
  sized sequence of `T`

Notation: Let's denote a sequence of `T` by `[T]`.

### Merkle tree API

We usually need at least two types of Merkle tree APIs:

- one which takes a sequence `S = [T]` of length `n` as input, and produces an 
  output (Merkle root) of type `T`
- and one which takes a sequence of bytes (or even bits, but in practice we probably 
  only need bytes): `S = [byte]`

We can decompose the latter into the composition of a function 
`deserialize : [byte] -> [T]` and the former.

### Naive Merkle tree implementation

A straightforward implementation of a binary Merkle tree `merkleRoot : [T] -> T` 
could be for example:

- if the input has length 1, it's the root
- if the input has even length `2*k`, group it into pairs, apply a 
  `compress : (T,T) -> T` compression function, producing the next layer of size `k`
- if the input has odd length `2*k+1`, pad it with an extra element `dummy` of 
  type `T`, then apply the procedure for even length, producing the next layer of size `k+1`

The compression function could be implemented in several ways:

- when `S` and `T` are just sequences of bits or bytes (as in the case of classical hash
  functions like SHA256), we can just concatenate the two leaves of the node and apply the
  hash: `compress(x,y) := H(x|y)`
- in case of hash functions based on the sponge construction (like Poseidon or Keccak/SHA3), 
  we can just fill the "capacity part" of the state with a constant (say 0), the "absorbing 
  part" of the state with the two inputs, apply the permutation, and extract a single `T` 

### Attacks

When implemented without enough care (like the above naive algorithm), there are several 
possible attacks producing hash collisions or second preimages:

1. The root of particular any layer is the same as the root of the input
2. The root of `[x_0,x_1,...,x_(2*k)]` (length is `n=2*k+1` is the same as the root of 
   `[x_0,x_1,...,x_(2*k),dummy]` (length is `n=2*k+2`)
3. when using bytes as the input, already `deserialize` can have similar collision attacks
4. The root of a singleton sequence is itself

Traditional (linear) hash functions usually solve the analogous problems by clever padding.

### Domain separation

It's a good practice in general to ensure that different constructions using the same 
underlying hash function will never produce the same output. This is called "domain separation",
and it can very loosely remind one to _multihash_; however instead of adding extra bits of information 
to a hash (and thus increasing its size), we just compress the extra information into the hash itself.
So the information itself is lost, however collisions between different domains are prevented.

A simple example would be using `H(dom|H(...))` instead of `H(...)`. The below solutions
can be interpreted as an application of this idea, where we want to separate the different
lengths `n`.

### Possible solutions (for the tree attacks)

While the third problem (`deserialize` may be not injective) is similar to the second problem,
let's deal first with the tree problems, and come back to `deserialize` (see below) later.

**Solution 0b.** Pre-hash each input element. This solves 2) and 4) (if we choose `dummy` to be
something we don't expect anybody to find a preimage), but does not solve 1); also it
doubles the computation time.

**Solution 1.** Just prepend the data with the length `n` of the input sequence. Note that any
cryptographic hash function needs an output size of at least 160 bits (and usually at least 
256 bits), so we can always embed the length (surely less than `2^64`) into `T`. This solves
both problems 1) and 2) (the height of the tree is a deterministic function of the length),
and 4) too.
However, a typical application of a Merkle tree is the case where the length of the input
`n=2^d` is a power of two; in this case it looks a little bit "inelegant" to increase the size
to `n=2^d+1`, though the overhead with above even-odd construction is only `log2(n)`.
An advantage is that you can _prove_ the size of the input with a standard Merkle inclusion proof.
Alternative version: append instead of prepend; then the indexing of the leaves does not change.

**Solution 2.** Apply an extra compression step at the very end including the length `n`, 
calculating `newRoot = compress(n,origRoot)`. This again solves all 3 problems. However, it 
makes the code a bit less regular; and you have to submit the length as part of Merkle proofs.

**Solution 3a.** Use two different compression function, one for the bottom layer (by bottom
I mean the closest to the input) and another for all the other layers. For example you can 
use `compress(x,y) := H(isBottomLayer|x|y)`. This solves problem 1).

**Solution 3b.** Use two different compression function, one for the even nodes, and another
for the odd nodes (that is, those with a single children instead of two). Similarly to the 
previous case, you can use for example `compress(x,y) := H(isOddNode|x|y)` (note that for 
the odd nodes, we will have `y=dummy`). This solves problem 2). Remark: The extra bits of 
information (odd/even) added to the last nodes (one in each layer) are exactly the binary 
expansion of the length `n`. A disadvantage is that for verifying a Merkle proof, we need to 
know for each node whether it's the last or not, so we need to include the length `n` into 
any Merkle proof here too.

**Solution 3.** Combining **3a** and **3b**, we can solve both problems 1) and 2); so here we add
two bits of information to each node (that is, we need 4 different compression functions).
4) can be always solved by adding a final compression call.

**Solution 4a.** Replace each input element `x_i` with `compress(i,x_i)`. This solves
both problems again (and 4) too), but doubles the amount of computation.

**Solution 4b.** Only in the bottom layer, use `H(1|isOddNode|i|x_{2i}|x_{2i+1})` for 
compression (not that for the odd node we have `x_{2i+1}=dummy`). This is similar to 
the previous solution, but does not increase the amount of computation.

**Solution 4c.** Only in the bottom layer, use `H(i|j|x_i|x_j)` for even nodes
(with `i=2*k` and `j=2*k+1`), and `H(i|0|x_i|0)` for the odd node (or alternatively
we could also use `H(i|i|x_i|x_i)` for the odd node). Note: when verifying
a Merkle proof, you still need to know whether the element you prove is the last _and_
odd element, or not. However instead of submitting the length, you can encode this
into a single bit (not sure if that's much better though).

**Solution 5.** Use a different tree shape, where the left subtree is always a complete
(full) binary tree with `2^floor(log2(n-1))` leaves, and the right subtree is
constructed recursively. Then the shape of tree encodes the number of inputs `n`.
Blake3 hash uses such a strategy internally. This however complicates the Merkle proofs 
(they won't have uniform size anymore).
TODO: think more about this!

### Keyed compression functions

How can we have many different compression functions? Consider three case studies:

**Poseidon.** The Poseidon family of hashes is built on a (fixed) permutation 
`perm : F^t -> F^t`, where `F` is a (large) finite field. For simplicity consider the case `t=3`. 
The standard compression function is then defined as:

    compress(x,y) := let (u,_,_) = perm(x,y,0) in u

That, we take the triple `(x,y,0)`, apply the permutation to get another triple `(u,v,w)`, and
extract the field element `u` (we could use `v` or `w` too, it shouldn't matter).
Now we can see that it is in fact very easy to generalize this to a _keyed_ (or _indexed_)
compression function:

    compress_k(x,y) := let (u,_,_) = perm(x,y,k) in u

where `k` is the key. Note that there is no overhead in doing this. And since `F` is pretty
big (in our case, about 253 bits), there is plenty of information we can encode in the key `k`.

Note: We probably lose a few bits of security here, if somebody looks for a preimage among
_all_ keys; however in our constructions the keys have a fixed structure, so it's probably
not that dangerous. If we want to be extra safe, we could use `t=4` and `pi(x,y,k,0)`
instead (but that has some computation overhead).

**SHA256.** When using SHA256 as our hash function, normally the compression function is
defined as `compress(x,y) := SHA256(x|y)`, that is, concatenate the (bitstring representation of the)
two elements, and apply SHA256 to the resulting (bit)string. Normally `x` and `y` are both
256 bits long, and so is the result. If we look into the details of how SHA256 is specified,
this is actually wasteful. That's because while SHA256 processes the input in 512 bit chunks,
it also prescribes a mandatory nonempty padding. So when calling SHA256 on an input of size 
512 bit (64 bytes), it will actually process two chunks, the second chunk consisting purely
of padding. When constructing a binary Merkle tree using a compression function like before,
the input is always of the same size, so this padding is unnecessary; nevertheless, people 
usually prefer to follow the standardized SHA256 call. But, if we are processing 1024 bits
anyway, we have a lot of free space to include our key `k`! In fact we can add  up to 
`512-64-1=447` bits of additional information; so for example

    compress_k(x,y) := SHA256(k|x|y)

works perfectly well with no overhead compared to `SHA256(x|y)`.

**MiMC.** MiMC is another arithmetic construction, however in this
case the starting point is a _block cipher_, that is, we start with
a keyed permutation! Unfortunately MiMC-p/p is a (keyed) permutation 
of `F`, which is not very useful for us; however in Feistel mode we
get a keyed permutation of `F^2`, and we can just take the first
component of the output of that as the compressed output.

### Making `deserialize` injective

Consider the following simple algorithm to deserialize a sequence of bytes into chunks of
31 bytes:

- pad the input with at most 30 zero bytes such that the padded length becomes divisible
  with 31
- split the padded sequnce into `ceil(n/31)` chunks, each 31 bytes.

The problem with this, is that for example `0x123456`, `0x12345600` and `0x1234560000` 
all results in the same output.

#### About padding in general

Let's take a step back, and meditate a little bit of what's the meaning of padding.

What is padding? It's a mapping from a set of sequences into a subset. In our case 
we have an arbitrary sequence of bytes, and we want to map into the subset of sequences 
whose length is divisible by 31.

Why do we want padding? Because we want to apply an algorithm (in this case a hash function) 
to arbitrary sequences, but the algorithm can only handle a subset of all sequences.
In our case we first map the arbitrary sequence of bytes into a sequence of bytes
whose length is divisible by 31, and then map that into a sequence of finite field
elements.

What properties do we want from padding? Well, that depends on what what properties we 
want from the resulting algorithm. In this case we do hashing, so we definitely want 
to avoid collisions. This means that our padding should never map two different input 
sequences into the same padded sequence (because that would create a trivial collision). 
In mathematics, we call such functions "injective".

How do you prove that a function is injective? You provide an inverse function, 
which takes a padded sequences and outputs the original one. 

In summary we need to come up with an injective padding strategy for arbitrary byte 
sequences, which always results in a byte sequence whose length is divisible by 31.

#### Some possible solutions:

- prepend the length (number of input bytes) to the input, say as a 64-bit little-endian integer (8 bytes),
  before padding as above
- or append the length instead of prepending, then pad (note: appending is streaming-friendly; prepending is not)
- or first pad with zero bytes, but leave 8 bytes for the length (so that when we finally append
  the length, the result will be divisible 31). This is _almost_ exactly what SHA2 does.
- use the following padding strategy: _always_ add a single `0x01` byte, then enough `0x00` bytes so that the length
  is divisible by 31. This is usually called the `10*` padding strategy, abusing regexp notation.
  Why does this work? Well, consider an already padded sequence. It's very easy to recover the
  original byte sequence by 1) first removing all trailing zeros; and 2) after that, remove the single
  trailing `0x01` byte. This proves that the padding is an injective function.
- one can easily come up with many similar padding strategies. For example SHA3/Keccak uses `10*1` 
  (but on bits, not bytes), and SHA2 uses a combination of `10*` and appending the bit length of the
  original input.

Remark: Any safe padding strategy will result in at least one extra field element
if the input length was already divisible by 31. This is both unavoidable in general,
and not an issue in practice (as the size of the input grows, the overhead becomes 
negligible). The same thing happens when you SHA256 hash an integer multiple of 64 bytes.


### Final proposal

We decided to implement the following version.

- pad byte sequences (to have length divisible by 31) with the `10*` padding strategy; that is, 
  always append a single `0x01` byte, and after that add a number of zero bytes (between 0 and 30),
  so that the resulting sequence have length divisible by 31
- when converting an (already padded) byte sequence to a sequence of field elements, 
  split it up into 31 byte chunks, interpret those as little-endian 248-bit unsigned
  integers, and finally interpret those integers as field elements in the BN254 prime 
  field (using the standard mapping `Z -> Z/p`).
- when using the Poseidon2 sponge construction to compute a linear hash out of 
  a sequence of field elements, we use the BN254 field, `t=3` and `(0,0,domsep)` 
  as the initial state, where `domsep := 2^64 + 256*t + rate` is the domain separation
  IV. Note that because `t=3`, we can only have `rate=1` or `rate=2`. We need
  a padding strategy here too (since the input length must be divisible by `rate`):
  we use `10*` again, but here on field elements. 
  Remark: For `rate=1` this makes things always a tiny bit slower, but we plan to use
  `rate=2` anyway (as it's twice as fast), and it's better not to have exceptional cases.
- when using Poseidon2 to build a binary Merkle tree, we use "solution #3" from above.
  That is, we use a keyed compression function, with the key being one of `{0,1,2,3}`
  (two bits). The lowest bit is 1 in the bottom-most (that is, the widest) layer,
  and 0 otherwise; the other bit is 1 if it's both the last element of the layer,
  _and_ it is an odd layer; 0 otherwise. In odd layers, we also add an extra 0 field
  element to make it even. This is also valid for the singleton input: in that case
  it's both odd and the bottommost, so the root of a singleton input `[x]` will
  be `H_{key=3}(x|0)`
- we will use the same strategy when constructing binary Merkle trees with the
  SHA256 hash; in that case, the compression function will be `SHA256(x|y|key)`.
  Note: since SHA256 already uses padding internally, adding the key does not
  result in any overhoad.
