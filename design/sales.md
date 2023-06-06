# Sales module

The sales module is responsible for selling a node's available storage in the
[marketplace](./marketplace.md). In order to do so it needs to know how much
storage is available. It also needs to be able to reserve parts of the storage,
to make sure that it is not used for other purposes.

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
                 reserved space |         | state
                                v         v
                   ----------------    -----------------
                   |     Repo     |    |   Datastore   |
                   ----------------    -----------------

The reservations module keeps track of storage that is available to be sold.
Users are able to add availability to indicate how much storage they are willing
to sell and under which conditions.

    Availability
      amount
      maximum duration
      minimum price

Availabilities consist of an amount of storage, the maximum duration and minimum
price to sell it for. They represent storage that is for sale, but not yet sold.
This is information local to the node that can be altered without affecting
global state.

## Adding availability

When a user adds availability, then the reservations module will check whether
there is enough space available in the Repo. If there is enough space, then it
will increase the amount of reserved space in the Repo. It persists the state of
all availabilities to the Datastore, to ensure that they can be restored when a
node is restarted.

    User          Reservations          Repo      Datastore
     |                  |                  |            |
     | add availability |                  |            |
     | ---------------->| check free space |            |
     |                  |----------------->|            |
     |                  | reserve amount   |            |
     |                  |----------------->|            |
     |                  |                               |
     |                  | persist availability          |
     |                  |------------------------------>|

## Selling storage

When a request for storage is submitted on chain, the sales module decides
whether or not it wants to act on it. First, it tries to find an availability
that matches the requested amount, duration, and price. If an availability
matches, but is larger than the requested storage, then the Sales module may
decide to split the availability into a part that we can use for the request,
and a remainder that can be sold separately. The matching availability will be
set aside so that it can't be sold twice.

It then selects a slot from the request to fill, and starts downloading its
content chunk by chunk. For each chunk that is successfully downloaded, a bit of
reserved space in the Repo is released. The content is stored in the Repo with a
time-to-live value that ensures that the content remains in the Repo until the
request expires.

Once the entire content is downloaded, the sales module will calculate a storage
proof, and submit the proof on chain. If these steps are all successful, then
this node has filled the slot. Once the other slots are filled by other nodes
the request will start. The time-to-live value of the content should then be
updated to match the duration of the storage request.

    Marketplace          Sales              Reservations      Repo
      |                    |                     |              |
      | incoming request   |                     |              |
      |------------------->| find reservation    |              |
      |                    |-------------------->|              |
      |                    | remove reservation  |              |
      |                    |-------------------->|              |
      |                    |                     |              |
      |                    | store content                      |
      |                    |----------------------------------->|
      |                    | set time-to-live                   |
      |                    |----------------------------------->|
      |                    | release reserved space             |
      |                    |----------------------------------->|
      |       submit proof |                                    |
      |<-------------------|                                    |
      |                    |                                    |
      .                    .                                    .
      .                    .                                    .
      | request started    |                                    |
      |------------------->| update time-to-live                |
      |                    |----------------------------------->|

## Ending a request

When a storage request comes to an end, then the content can be removed from the
repo and the storage space can be made available for sale again. The same should
happen when something went wrong in the process of selling storage.

The time-to-live value should be removed from the content in the Repo, reserved
space in the Repo should be increased again, and the availability that was used
for the request can be re-added to the reservations module.

                         Sales              Reservations      Repo
                           |                     |              |
                           |                     |              |
                           |                                    |
                           | remove time to live                |
                           |----------------------------------->|
                           | increase reserved space            |
                           |----------------------------------->|
                           |                                    |
                           | re-add availability |              |
                           |-------------------->|              |
                           |                     |              |

## Persisting state

The sales module keeps state in a number of places. Most state is kept on chain,
this includes the slots that a host is filling and the state of each slot. This
ensures that a node's local view of slot states does not deviate from the
network view, even when the network changes while the node is down. The rest of
the state is kept on local disk by the Repo and the Datastore. How much space is
reserved to be sold is persisted on disk by the Repo. The availabilities are
persisted on disk by the Datastore.

## Request queue

Once a new request for storage is created on chain, all hosts will receive a
contract event announcing the storage request and decide if they want to act on
the request by matching their availabilities with the incoming request. Because
there will be many requests being announced over time, each host will create a
queue of matching requests, adding each new storage request to the queue.

### Adding requests to the queue

Requests will be added to the queue when request for storage events are received
from the contracts. Additionally, when slots are freed, a contract event will
also be received, and the request (and slot index) will be added to the queue.
If the request of the freed slot already exists in the queue, the entry will be
updated to include the slot index (multiple slot indices should be allowed).

### Removing requests from the queue

Hosts will also recieve contract events for when any contract is started,
failed, or cancelled. In all of these cases, requests in the queue should be
removed as they are no longer fillable by the host. Note: expired requests will
be checked when a request is processed and its state is validated.

### Sort order

Requests in the queue should be sorted in the following order:
1. Profit (descending, yet to be determined how this will be calculated)
2. Collateral required (ascending)
3. Time before expiry (descending)
4. Dataset size (ascending)

Note: datset size may eventually be included in the profit algorithm and may not
need to be included in the future. Additionally, data dispersal may also impact
the datset size to be downloaded by the host, and consequently the profitability
of servicing a storage request, which will need to be considered in the future
once profitability can be calculated.

### Queue processing

Queue processing will be started only once, when the sales module starts and
will process requests continuously, in order, until the queue is empty. If the
queue is empty, processing of the queue will resume once items have been added
to the queue. If the queue is not empty, but there are no availabilities, queue
processing will resume once availabilites have been added.

When a request is processed, it first is checked to ensure there is a matching
availabilty, as these availabilities will have changed over time. Then, a random
slot will be chosen, and the sales process will begin. If the request being
processed contains one or more slot indices (as in the case of repair), the
random slot should be chosen from that sample of indices. The start of the sales
process should ensure that the random slot chosen is indeed available (slot
state is "free") before continuing. If it is not available, the sales process
will exit and the host will process the top request in the queue. Note: it may
be that the top request in the queue is the same request that was just
processed, indicating that the request still has slots to be filled, as the
request was had not yet been removed due to being started/failed/cancelled. This
re-processing of the same request allows for the possibility that the random
slot index chosen had already been filled by another host, and gives the host a
chance to fill a different slot index of the same request.

### Implementation tips

Request queue implementations should keep in mind that requests will likely need
to be accessed randomly (by key, eg request id) and by index (for sorting), so
implemented structures should handle these types of operations in as little time
as possible.

## Repo

The Repo exposes the following functions that allow the reservations module to
query the amount of available storage, to update the amount of reserved
space, and to store data for a guaranteed amount of time.

    Repository API:
      function available(): amount
      function reserve(amount)
      function release(amount)
      function setTtl(cid, ttl)

## Datastore

The Datastore is a generic key-value store that is used to persist the state of
the Reservations module, so that it survives node restarts.

    Datastore API:
      function put(key, value)
      function get(key): value
