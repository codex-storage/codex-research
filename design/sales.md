Sales module
============

The sales module is responsible for selling a node's available storage in the
[marketplace](./marketplace.md). In order to do so it needs to know how much
storage is available. It also needs to be able to reserve parts of the storage,
to make sure that it is not used for other purposes while we are filling a slot
in a storage request, or while we're attempting to fill a slot.

    ---------------------------------------------------
    |                                                 |
    |    Sales                                        |
    |                                                 |
    |    ^   |                                        |
    |    |   |    updates    ------------------       |
    |    |   --------------> |                |       |
    |    |                   |  Reservations  |       |
    |    ------------------- |                |       |
    |          queries       ------------------       |
    |                           ^         ^           |
    ----------------------------|---------|-----------
                                |         |
                  availability  |         | state
                                v         v
                   ----------------    -----------------
                   |     Repo     |    |   Datastore   |
                   ----------------    -----------------

The Sales module keeps track of storage reservations in its internal
Reservations module. It keeps a record of which pieces of reserved storage
belong to which storage request slot. It queries and updates the amount of
available storage in the Repo. It uses a Datastore to persist its own state.

The Repo exposes the following functions that allow the Reservations module to
query and update the amount of available storage:

    Repository API:
      function available(): amount
      function reserve(amount)
      function release(amount)

The Datastore is a generic key-value store that is used to persist the state of
the Reservations module, so that it survives node restarts.

    Datastore API:
      function put(key, value)
      function get(key): value

Reserving storage space
-----------------------

When a request for storage is submitted on chain, the sales module decides
whether or not it wants to act on it. If the requested duration and size match
what the node wants to sell and the reward is sufficient, then the sales module
will go through several steps to try and fill a slot in the request.

First, it will select a slot from the request to fill. Then, it will reserve
space in the Repo to ensure that it keeps enough space available to store the
content. It will mark the reserved space as belonging to the slot. Next, it will
download the content, calculate a storage proof, and submit the proof on chain.
If any of these later steps fail, then the node should release the storage that
it reserved earlier.

When a slot was filled successfully, then its storage should not be released
until the request ends.

Releasing storage space
-----------------------

When a storage request ends, or an attempt to fill a slot fails, it is important
to release the reserved space that belonged to the slot. To ensure that the
right amount of space is released, and that it is only released once, we keep
track of how much space is reserved in the Repo for a slot.

Releasing storage space goes in three steps. First, we look up the amount of
space that is reserved for the slot in the Datastore. Then we release that
amount in the Repo, and remove the entry for the slot from the Datastore.

The first step ensures that we release the correct amount of space from the
Repo. The last step ensures that we do not release space from the Repo more than
once.

Persisting state
----------------

The sales module keeps state in a number of places. Most state is kept on chain,
this includes the slots that a host is filling and the state of each slot. This
ensures that a node's local view of slot states does not deviate from the
network view, even when the network changes while the node is down. The rest of
the state is kept on local disk by the Repo and the Datastore. How much space is
reserved by the sales module, and how much remains available to sell is
persisted on disk by the Repo. A mapping between amounts of reserved space and
slots is persisted on disk by the Datastore.
