# Ecosim


## TODO

 ### Infra

 - [ ] Create new domain name ecosim.fr

 ### Review

### First simulation
 - [ ] Study market, simple case
 - [ ] Simulate a case with one producer and one buyer
    - [ ] Create a test scenario
    - [ ] Module Market
    - [ ] Module Market.Supervisor
    - [ ] Module Market.Server
    - [ ] Module Market.Simulator

## Architecture

Use a dynamic supervisor to launch Market.Supervisor on demand.
This server will start a supervisor and launch the server.
The server will have a function, add_player that will add a new player
which will be a process that handled user action.


## Incremental creation

1. Work on the Simulator first and test it
1. Simulator should run one round and produce a new market state
1. Market state should be an average price

2. Create simulation should create a Market, look at channel and display a code
3. Join channel


## First simulation: market

Each player is assigned a role:
- producer
- buyer

A producer has a known production capacity. Every player has the same. They also have a production cost per object.
A buyer has a know quantity to buy. Every player has the same.

At each round, buyer offer a price and producer sell to a price. We display the distribution of each

A producer has a production cost under which selling is no longer profitable.
A buyer has a budget above which they cannot buy anymore. This needs to be distributed in a way that high budget are rare and low budget are frequent. This will simulate that people able to pay high price are few.
The same for producer. They should not be able to sell sometimes.

Each round

The goal is to find the right price where demand matches offer. We represent the average price on a graph and how many were sold at this price on the same graph for each round until we find the right price. Then we use all the point to trace the supply curve and the demand curve.

