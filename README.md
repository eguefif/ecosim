# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.

## TODO

- [ ] Check for uniqueness in participants list
- [ ] Create mode multi
    - [x] add subscriber's list to SimManager
    - [x] Add the first liveview to this list via monitor and demonitor functions
    - [x] have two broadcast function: broadcast_all, broadcast_participants
    - [x] broadcast message for add_participants (except liveview) + update
    - [x] broadcast when liveview is down to all clients execept liveview
    - [x] Upon receiving a message, get sim info in market_live.ex
    - [x] Upon receiving a message, get participants list to display
    - [ ] When user start joining
        - [x] Add the name to the sim participant list
        - [ ]  redirect to market_sim\[id]
            - [x] Subscribe to sim event
            - [x] Upon message, get info
            - [x] In prep, show a message asking to wait
            - [x] In result, show a message asking to see the main screen
            - [x] In sim, display the role, a form to offer a price, a list of counterpar role offers
            - [ ] Show offers and transaction
            - [ ] Make input and offer button add a new offer
            - [ ] Click on a price, scale up the card, show a take offer button
            - [ ] Show the period index number
    - [x] Monitor participant's liveviews to remove them when waiting for participants. Then we should just ignore in sim.


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

## Sim ideas

- Create offer and demand graph
- Run my company to understand budget ...

## Author

Emmanuel Guefif

## Sim and abstraction

The SimulationServer will provide the following function

- new: takes a simulation type and register the caller process to the consumer list of Pub/Sub
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

### Pub/Sub mechanism

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
