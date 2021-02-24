# Dagger Storage Engine

> This document provides a high level overview of the Storage Engine and its components

## Storage Engine

The storage engine is in charge of storing, finding, syncing and retrieving data from the Dagger Network.

At a high level, the storage engine is composed of:

- Merkle-Dag data structure - which allows storing and representing arbitrary data structures in a distributed graph
  - This data structure that allows representing any type of hierarchical or flat formats
  - Uses block decoders and [CIDs](https://github.com/multiformats/cid) to navigate and parse the data stored on the network
- Block Stores - the block store is an abstraction that deals with chunks or blocks. Blocks are the smallest addressable unit in the system. The mechanism to uniquely identify a block is the [CID](https://github.com/multiformats/cid) or content identifier.
  - The **network** store implements the functionality required to retrieve and store (upload) blocks to the network
  - The **local** store interacts with the local filesystem or a local DB. For example, we can store blocks directly in the filesystem or we can store metadata about the block in a local db. The metadata can be pointers or offsets to blocks in a file along with it's [CID](https://github.com/multiformats/cid) hash. Different schemes are possible.

## Architecture

The storage engine architecture is loosely based on IPFS however, we make no promises to maintain compatibility at any level except perhaps [multiformats](https://github.com/multiformats) and the [merkle dag](https://docs.ipfs.io/concepts/merkle-dag/). Currently some protocols are being implemented verbatim but will be extended or swapped out as needed.

Bellow is a high level diagram of the storage engine:

```
+-----------------------------------------------------------------------------------------+
|   Dagger Storage Engine                                                                 |
| +--------------------------------------------------------------------------------------+|
| |   Merkle DAG                                                                         ||
| | +-----------------------------------------------------------------------------------+||
| | | Block Decoders/Encoders (CID)                                                     |||
| | |+-----------------+  +-----------------+   +-----------------+  +-----------------+|||
| | ||                 |  |                 |   |                 |  |                 ||||
| | || Bittorrent      |  | Ethereum Blocks |   | Git Blocks      |  |     Etc...      ||||
| | || Blocks          |  | (Chunks)        |   |                 |  |                 ||||
| | |+-----------------+  +-----------------+   +-----------------+  +-----------------+|||
| | +-----------------------------------------------------------------------------------+||
| +-------------------------------------------^------------------------------------------+|
|                                             |                                           |
|                                             |                                           |
| +-------------------------------------------v------------------------------------------+|
| |   Block Stores                                                                       ||
| |+---------------------------------------+  +---------------------------------------+  ||
| ||          Local (Filesystem)           |  |            Remote (Network)           |  ||
| ||+----------------+  +----------------+ |  |+----------------+   +----------------+|  ||
| |||  SQLite Chunk  |  |  File System   | |  ||Block Discovery |   | Block Download ||  ||
| |||  Store         |  |  Chunk Store   | |  ||(DHT/etc..)     |   | and Replication||  ||
| |||                |  |                | |  ||                |   |                ||  ||
| ||+----------------+  +----------------+ |  |+----------------+   +----------------+|  ||
| |+-------------------^-------------------+  +-------------------^-------------------+  ||
| +--------------------|------------------------------------------|----------------------+|
|                      |                                          |                       |
|                      |                                          |                       |
|+---------------------v--------------------+   +-----------------v----------------------+|
||                                          |   |                                        ||
||                                          |   |                                        ||
||             File System                  |   |         Network (libp2p)               ||
||                                          |   |                                        ||
|+------------------------------------------+   +----------------------------------------+|
+-----------------------------------------------------------------------------------------+
```

## Uploading and Downloading data

The flow to upload data consists of:

- Taking a file (or any data blob) and splitting it into blocks or chunks
- Hashing the content of the block to generate it's CID
  - Hashing is done using the [multihash](https://github.com/multiformats/multihash). Any hashing method supported by the multihash format is also supported in Dagger.
- Using the objects CID to select a block encoder and subsequently encode the blocks into a suitable merkle dag structure according to the format's rules
  - The merkle dag support any sort of hierarchical or flat format, for example the blocks can be encoded into a chain of chunks or more complex structures such as a merkle trie or even git repo
- Finding suitable nodes and uploading the chunks to the network
  - The engine merrely pushes blocks to nodes and makes no assumptions about neither
    - how the nodes where located (DHT, peer exchange mechanisms, etc...) nor
    - how transfers are accounted for
      - For example, it's possible to have have a simple "tit-for-tat" accounting mechanis or a more complex one that involves economic incentives
  - If uploading of a block fails, the engine simply invokes the discovery mechanism again to select more nodes until the upload of all the required blocks is complete

Downloading data consists of:

- Getting the hash of an object
- Using some discovery mechanism to locate nodes that hold this object
  - This is most likely a DHT, but as already mentioned, the storage engine makes no assumptions about this
- Once a node with the object is located and a connection is established
- The block is downloaded and handed over to the merkle dag
- The merkle dag uses the objects CID to select a suitable block parser to parse the object
  - If the object is a node that points to other objects, the merkle dag invokes the block store which will check if the block is in the local store and if not repeat the flow again until all desired objects are retrieved

Each step above involves one or more previously introduced componets. The following sections provide a more in depth overview of each of this components.

### Chunking files

- TODO

### Block Exchange

Downloading and uploading data in the network is done using an extended version of the Bitswap protocol as currently described [here](https://github.com/ipfs/go-bitswap/blob/master/docs/how-bitswap-works.md). The protocol is further extended to support pushing blocks to remotes, which is departure from the current bitswap model.

### Merkle Dag

- TODO

### Local chunk persistance

- TODO
