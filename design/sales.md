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
      maximum collateral price

Availabilities consist of an amount of storage, the maximum duration and minimum
price to sell it for. They represent storage that is for sale, but not yet sold.
This is information local to the node that can be altered without affecting
global state.

## Selling strategy

We ship a basic algorithm for optimizing the selling process. It does not aim to be 
the best algorithm, as there might be different strategies that users might want to adapt.
Instead, we chose to provide a basic implementation and, in the future, expose the 
internals of decision-making to the users through an API. This will give them the option 
to plug in more robust and custom strategies. The main design goal of our selling strategy 
is the maximization of utilized capacity with the most profitable requests. 
This decision leads to several behaviors that we describe below.

We do not wait for potentially more profitable requests to arrive sometime later on, 
as defining this waiting period is not trivial. Because while waiting, you might miss 
out on current opportunities.

When we have availability for sale, we aim to fill slots right away. This means it 
is crucial to have the current market state available to choose from at the moment 
when the availability is added or returned.

If the size of our currently available storage space does not suffice to fill the most 
profitable slots, we choose less profitable ones that fit into our free space.

Availabilities probably won't ever be fully utilized as the probability of finding 
the right-sized slot is very low. Hence, the algorithm needs to take it into consideration.

All the previously mentioned behaviors are limited by user-specified constraints, 
which are passed as parameters when creating availability. Most of this behavior 
is implemented through an ordered slot list, as described below.

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

## Ordered slot list

The ordered slot list is a list where slots that are currently seeking a host to 
fill them are stored. It is capped at a certain capacity and ordered by 
profitability (which will be described later). The most profitable slots are at
the beginning, while the least profitable ones are at the end.

### Adding slots to the list

Slots will be added to the list when requests for storage events are received
from the contracts. Additionally, when slots are freed, a contract event will
also be received, and the slot will be added to the list. Duplicates are
ignored.

When all slots of a request are added to the queue, the order should be randomly
shuffled. This is because there will be many hosts in the network that could 
potentially pick up the request and process the first slot in the queue
simultaneously. Randomly shuffling the order will help avoid clashes in slot
indices chosen by competing hosts.

If the list were to exceed its capacity with the new slot, the tail would be 
removed, but only if the tail's profitability is lower than that of the new slot.
Otherwise, the new slot is discarded.

### Removing slots from the list

Hosts will also receive contract events for when any contract is started,
failed, or cancelled. In all of these cases, slots in the list pertaining to
these requests should be removed as they are no longer fillable by the host.
Note: expired request slots will be checked when a request is processed and its
state is validated.

### Sort order

Slots in the queue should be sorted in the following order:
1. Profit (descending)<sup>1</sup>
2. Collateral required (ascending)
3. Time before expiry (descending)
4. Dataset size (ascending)

<sup>1</sup> While profit cannot yet be calculated correctly as this calculation will
  involve bandwidth incentives, profit can be estimated as `duration * reward`
  for now.

Note: dataset size may eventually be included in the profit algorithm and may not
need to be included on its own in the future. Additionally, data dispersal may
also impact the dataset size to be downloaded by the host, and consequently the
profitability of servicing a storage request, which will need to be considered
in the future once profitability can be calculated.

## Slot list processing

Slot list processing is triggered by three cases:

1. When the node is starting.
2. When there is a change to the availabilities set, either a new one is added 
or the capacity is changed.
3. When new slots are added to the slot list.

Processing works using a pool of workers, which are there to control the speed at
which the slots are filled. There are limitations on the number of slots that can 
be filled simultaneously due to bandwidth constraints, etc. Each worker fills only
one slot at a time. The number of workers should be configurable.

When processing is triggered, a worker starts iterating through the slot list from 
the beginning (e.g., the most profitable slots) and matches them against the node's
availabilities. If there is a match, it will mark that given slot as reserved 
(to prevent other workers from double-processing it) and start the state machine. 
Once the state machine reaches the Filled state, the worker is returned to the 
worker pool along with the successful result. If the previous result was successful,
this process repeats until the previous result is "failure", which occurs when there
is no match for any of the slots. This way, the process finishes as there is a 
limited number of availabilities and their capacities.

### Asynchronicity
The implementer should keep in mind that there are problems regarding the asynchronicity
of triggering the processing and accessing/modifying the slot list.

First problem is related to the fact that the processing can be triggered from 
multiple points, and as the processing might be quite time-consuming when filling
slots, it might happen that multiple processing processes could be running at the
same time, which should not be the case. Realistically, the processing will be 
mostly called from the "new slots added to list" point.
There is a possibility of using locks, but that might lead to growing the async 
dispatcher queue and potential issues connected with that.
Another option could be to have a function called `scheduleProcessing()` which would
behave in a similar fashion as a singleton, allowing only one running processing at a time. 
However, it should allow scheduling of one more processing run if there is currently 
processing running. This is because the processing might be iterating in the middle
of the ordered list and would not take in consideration the changes that were
introduced in the beginning of the list.

The second problem is related to mutations of the slot list while processing it, 
where the list could be changing under the "worker's hand" as the changes come from
blockchain events. A potentially sufficient mitigation for this could be to keep the 
iteration over the slot list completely synchronous. Perform all the asynchronous 
data fetching before the list iteration and avoid yielding in the loop.

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
