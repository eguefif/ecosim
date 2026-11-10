# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.


## Next TODO

- [ ] Design simulation page in market_live: sim component
- [ ] In Result, show the supply and demand theoritical plots.
- [ ] Show all price and change the UI for accepting price. Just click on the price and it shows an actor selector that will accept the price.
- [ ] End to end test


### Refactor Market

 - [ ] User chooses a demand and offer market model
 - [ ] We pass to Market.new the list of name and market model and it generates the actors itsef
    - [ ] Refactor Market.new to take a list of names only and equaly distribute among seller and buyer and use prefedined WT
    - [ ] Refactor UI: display all offers all the time: can click on offer and select
    buyer or seller
    - [ ] Reset all price when transaction done
    - [ ] Keep list of actions and transaction
    - [ ] Add the market model for model 1
    - [ ] Add the market model for model 2
    - [ ] Add the market model for model 3


## Roadmap

1. Create the mode Multi
2. Create the mode One user with bots
3. Improve market simulator with tax
4. Improve market simulator with monopole
5. Add simulator bank and monetary creation, credits make deposits
6. Add simulator on inflation

## Author

Emmanuel Guefif
