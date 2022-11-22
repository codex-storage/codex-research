Sales module
============

The sales module is responsible for selling a node's available storage in the
[marketplace](./marketplace.md). In order to do so it needs to know how much
storage is available. It also needs to be able to reserve parts of the storage,
to make sure that it is not used for other purposes while a contract is running
or being negotiated.

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
belong to which storage contract. It queries and updates the amount of available
storage in the Repo. It uses a Datastore to persist its own state.

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
