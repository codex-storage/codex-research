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

## Slot queue

Once a new request for storage is created on chain, all hosts will receive a
contract event announcing the storage request and decide if they want to act on
the request by matching their availabilities with the incoming request. Because
there will be many requests being announced over time, each host will create a
queue of matching request slots, adding each new storage slot to the queue.

### Adding slots to the queue

Slots will be added to the queue when request for storage events are received
from the contracts. Additionally, when slots are freed, a contract event will
also be received, and the slot will be added to the queue. Duplicates are
ignored.

When all slots of a request are added to the queue, the order should be randomly
shuffled, as there will be many hosts in the network that could potentially pick
up the request and will process the first slot in the queue at the same time.
This should avoid some clashes in slot indices chosen by competing hosts.

Before slots can be added to the queue, availabilities must be checked to ensure
a matching availability exists. This filtering prevents all slots in the network
from entering the queue.

### Removing slots from the queue

Hosts will also receive contract events for when any contract is started,
failed, or cancelled. In all of these cases, slots in the queue pertaining to
these requests should be removed as they are no longer fillable by the host.
Note: expired request slots will be checked when a request is processed and its
state is validated.

### Sort order

Slots in the queue should be sorted in the following order:
1. Profit (descending)<sup>1</sup>
2. Collateral required (ascending)
3. Time before expiry (descending)
4. Dataset size (ascending)
5. Seen flag

<sup>1</sup> While profit cannot yet be calculated correctly as this calculation will
  involve bandwidth incentives, profit can be estimated as `duration * reward`
  for now.

Note: datset size may eventually be included in the profit algorithm and may not
need to be included on its own in the future. Additionally, data dispersal may
also impact the datset size to be downloaded by the host, and consequently the
profitability of servicing a storage request, which will need to be considered
in the future once profitability can be calculated.

### Queue processing

Queue processing will be started only once, when the sales module starts and
will process slots continuously, in order, until the queue is empty. If the
queue is empty, processing of the queue will resume once items have been added
to the queue. If the queue is not empty, but there are no availabilities, queue
processing will resume once availabilites have been added.

As soon as items are available in the queue, and there are workers available for
processing, an item is popped from the queue and processed.

When a slot is processed, it is first checked to ensure there is a matching
availability, as these availabilities will have changed over time. Then, the
sales process will begin. The start of the sales process should ensure that the
slot being processed is indeed available (slot state is "free") before
continuing. If it is not available, the sales process will exit and the host
will continue to process the top slot in the queue. The start of the sales
process should also check to ensure the host is allowed to fill the slot, due to
the [sliding window
mechanism](https://github.com/codex-storage/codex-research/blob/master/design/marketplace.md#dispersal).
If the host is not allowed to fill the slot, the sales process will exit and the
host will process the top slot in the queue.

#### Preventing continual processing when there are small availabilities
If the processed slot cannot continue because there are no availabilities, the
slot should be marked as `seen` and put back into the queue. This flag will
cause the slot to be ordered lower in the heap queue. If, upon processing
a slot, the slot item already has a `seen` flag set, the queue should be
paused.

This serves to prevent availabilities that are small (in avaialble bytes) from
emptying the queue.

#### Pausing the queue
When availabilities are modified or removed, and there are no availabilities
left, the queue should be paused.

A paused queue will wait until it is unpaused before continuing to process items
in the queue. This prevents unnecessarily popping items off the queue.

#### Unpausing the queue
When availabilities are modified or added, the queue should be unpaused if it
was paused and any slots in the queue should have their `seen` flag cleared.

#### Queue workers
Each time an item in the queue is processed, it is assigned to a workers. The
number of allowed workers can be specified during queue creation. Specifying a
limited number of workers allows the number of concurrent items being processed
to be capped to prevent too many slots from being processed at once.

During queue processing, only when there is a free worker will an item be popped
from the queue and processed. Each time an item is popped and processed, a
worker is removed from the available workers. If there are no available workers,
queue processing will resume once there are workers available.

#### Adding availabilities
When a host adds an availability, a signal is triggered in the slot queue with
information about the availability. This triggers a lookup of past request for
storage events, capped at a certain number of past events or blocks. The slots
of the requests in each of these events are added to the queue, where slots
without matching availabilities are filtered out (see [Adding slots
to the queue](#adding-slots-to-the-queue) above). Additionally, when slots of
these requests are processed in the queue, they will be checked to ensure that
the slots are not filled (see [Queue processing](#queue-processing) above).

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
