# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.

## TODO

- [ ] Refactor current `market.ex` and `market_live.ex`, it should only use `market.ex` for everything
    - [ ] `new/0`: returns a market with initial `market_model` set to 1
    - [ ] `update(market, command, params \\ %{})` should handle the following:
        - [ ] `:add_actors`, takes a list of actors
        - [ ] `:change_period`
        - [ ] `:change_step`
        - [ ] `:change_market_model`
        - [ ] `:init_simulation` will use the current list of participants and create wt's and distribution
    - [ ] `info(market)`: returns a map depending on the step
        - [ ] `:preparation`: returns the current list of participants and market_model
        - [ ] `:sim`: returns the list of transactions, the list of active actors with their last offer, actor's type and wt
        - [ ] `:result`: returns the market_data, price_per_transaction, quantity per period datasets
- [ ] Create a `Simulator` module to handle logic and define state model
    - [ ] Keep track of list of actors
    - [ ] Keep track of simulation type via the Module name
    - [ ] keep track of the joining code
    - [ ] Provides the following interface
        - [ ] `start_links(simulation_type)`, register the GenServer to the registry using via and create a joining code, returns a Simulator. Use the self() before starting the genserver to register the liveview as a event consummer.
        - [ ] `join_code`: returns the join_code
        - [ ] `add_participants`: add participants
        - [ ] `update(command, params \\ %{})` update the sim
        - [ ] `info()`: returns a map with the sim information
- [ ] Create a `SimulatorServer` to handle simulation state
    - [ ] Create a `Simulator`
    - [ ] Monitor the associated liveview process
- [ ] Create a `SimulatorRegistry` to keep track of simulation

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

The SimulationServer will provide the following function

- new: takes a simulation type and register the caller proces to the consumer list of Pub/Sub
- join: add a user and register the caller pid to an event consummer list for Pub/Sub
- update_sim: call the Simulation.update function
- info: call the Simulation.info function


### Simulation module

Each module will provides the following function
- new: takes a simulation type
- update: include undo last action for some simulation, change step too
- info: returns different entry depending on the step
    - if preparation step: returns preparation data like market model
    - if simulation step: returns info to show simulation state
    - if results step: returns results data

### Pub/Sub mechanisme

Each process, the simulation_liveview and user_liveview can update the simulator. Any time the Server receives update, at the end of the modification, it triggers a broadcast to all process to tell them the state has been updated.
Upon receiving this message, all liveview process send a message via the info function and get the new state to display to the user.


### Links between process

A new simulation will create a new SimulationServer registered to the SimulationRegistry.
A user can join the simulation by retrieving the SimulationServer process and use its interface to join.

If the simulation stops, it will stop the SimulationServer. The SimulationRegistry will removes the key.

How to tell a user that the simulation has stop ? We can monitor the liveview in the SimulationServer and have a function that broadcast the end of the simulation. A user can show a page saying that the simulation has stoped.


### What happens

When creating a new simulation:
1. new live_view
2. This live_view start_link a SimulationServer
3. The simulation server create an random id and register itself to the simulation_registry and keep the caller process id as an event consumer
4. Returns the GenServer pid()
5. It uses the server client interface to send message



When joining a new simulation:
1. In the joining liveview: user type the joining code, a name and click join
2. Check the registry and get the type, build the url and redirect user to the user_live.ex
3. The user_live.ex get the server, register the new user and subscribe to the GenServer event.
4. Each time we receive handle_info("sim-update"), we refresh state using info()


## PubSub

We won't use the pub sub system. We will register the sim_liveview and user_liveview processes in the GenServer.
Anytime an update is trigger, it send a message to all liveviews. On receiving this message, liveviews will use the `info` function to send a message to the simulator and retrieve the new state.
