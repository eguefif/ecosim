# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.

## TODO

- [ ] Multi: create a key/value registry for code that returns the url to join.
- [ ] Add PubSub based on the join code to Market and when a user join, it tells the main liveview and add the user to actors list
- [ ] THe user should also subscribe to the market pubsub to get information.
- [ ] It will always pass the market and a list of user.
- [ ] Find a way to delete keys from ets that are no longer in use.

    - [ ] Mode multi


### Join Code handling
- [ ] Monitor simulation in a Genserver that monitor simulations.
- [ ] Keep the code in the Genserver.
- [ ] When a simulation ends, destroy the code and the simulation from the registry.

## Roadmap

1. Create the mode Multi
2. Create the mode One user with bots
3. Improve market simulator with tax
4. Improve market simulator with monopole
5. Add simulator bank and monetary creation, credits make deposits
6. Add simulator on inflation

## Author

Emmanuel Guefif

## Sim and abstraction

A sim has a simulation_state and participants and the following interface:
- new
- start
- join

simulation_state:
- simulation_type: market, ...
- participants: list of participants
- join_code
- liveview process pid

A sim is related to a simulation liveview like market_live.ex. It monitors the process and it's link to
it. If the liveview stops, the genserver stops.

A sim is registered to a registry to keep track of simulation.

Create a Ecosim.Sim GenServer that provides 5 functions:
- new: takes a simulation type
- join
- start_sim
- update_sim: include undo last action for some simulation, change step too
- info: returns different entry depending on the step
    - if preparation step: returns preparation data like market model
    - if simulation step: returns info to show simulation state
    - if results step: returns results data


Each Simulator should implements the following functions: 
- new: takes a list of actor and other options
- update
- undo
- info
- results
Info and results should have a description in the documentation to know how map are organized.
Same for update and new.
When creating a sim, we use the SimRegistry to keep track of all sim
Each Sim has a code to allow user to join.

When a user join, the SimSupervisor tells the user the ref of the sim. It can retrieve info from the sim and
know what URL to join and use info and stuff.


## Task

- [ ] Refactor market.ex, market_live.ex to work with the new interface
- [ ] Create sim.ex, sim_server.ex and add tests
- [ ] Create sim registry to allow a user to join the sim
