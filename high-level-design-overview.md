# Dagger Storage Engine PoC Overview

> This is meant as both a high level overview of the storage engine PoC as well as a place to discuss different aspects of the architecture and it's components.

## Storage Engine

The storage engine is in charge of storing, finding, syncing and retrieving data from the Dagger Network.

At a high level, the storage engine is composed of:

- Merkle-Dag data structure - which allows storing and representing arbitrary data structures in a distributed graph
  - This data structure allows representing any type of hierarchical or flat formats
  - Uses block decoders and [CIDs](https://github.com/multiformats/cid) to navigate and parse the data stored on the network
- Block Stores - the block store is an abstraction that deals with chunks or blocks. Blocks are the smallest addressable unit in the system. The mechanism to uniquely identify a block is the [CID](https://github.com/multiformats/cid) or content identifier.
  - The **network** store implements the functionality required to retrieve and store (upload) blocks to the network
  - The **local** store interacts with the local filesystem or a DB.
    - For example, either the blocks or the blocks metadata or both, can be stored on the local store. In the case of metadata, a local DB such as SQLite can be used to store the block's hash and offset or similar information. Different schemes are possible.

## Architecture

The architecture is loosely based on IPFS however, we make no promises to maintain compatibility at any level except perhaps [multiformats](https://github.com/multiformats) and the [merkle dag](https://docs.ipfs.io/concepts/merkle-dag/). Some protocols are being implemented verbatim but will be extended or swapped out as needed.

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
| |||  SQLite Chunk  |  |  File System   | |  ||Block Discovery |   | Block Exchange ||  ||
| |||  Store         |  |  Chunk Store   | |  ||(DHT/etc..)     |   |                ||  ||
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
- Using the object's CID to select a block encoder and subsequently encode the blocks into a suitable merkle dag structure
  - The merkle dag support any sort of hierarchical or flat format. For example the blocks can be encoded into a chain of chunks or more complex structures such as a merkle trie
- Finding suitable nodes and uploading the chunks to the network
  - The engine merely pushes blocks to nodes and makes no assumptions about neither
    - how the nodes where located (DHT, peer exchange mechanisms, etc...) nor
    - how transfers are accounted for
      - For example, it's possible to have have a simple "tit-for-tat" accounting mechanism or a more complex one that involves economic incentives
  - If uploading of a block fails, the engine simply invokes the discovery mechanism again to select more nodes until the upload of all the required blocks is complete

Downloading data consists of:

- Getting the hash of an object
- Using some discovery mechanism to locate peers that hold this object
  - This is most likely a DHT, but as already mentioned, the storage engine makes no assumptions about this
- Once a peer with the object is located and a connection is established
- The block is downloaded and handed over to the merkle dag
- The merkle dag uses the object's CID to select a suitable block parser to parse the object
  - If the object is a node that points to other objects, the merkle dag invokes the block store which will check if the block is in the local store and if not repeat the flow again until all desired objects are retrieved

### TODOs:

- [ ] Implement Block Exchange
  - [x] Basic block exchange (currently based on Bitswap)
  - [ ] Block sync
    - [ ] It is still unclear if this is required (needs RFC)
- [ ] Implement Merkle-Dag
  - [ ] Figure how blocks are stored on the dag (needs RFC)
- [ ] Discovery
  - [ ] DHT but it needs some further discovery (needs RFC)
- [ ] Local store
  - [ ] Figure out how blocks for local files are stored and served (needs RFC)
  - [ ] Figure out how remote blocks are stored (needs RFC)
