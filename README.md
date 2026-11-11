# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.



## TODO

- [ ] Refactor update(:accept), it needs to take sellers and buyers and a price. Find the best way


- [ ] Design simulation page in market_live: sim component
- [ ] In Result, show the supply and demand theoritical plots.
- [ ] Show all price and change the UI for accepting price. Just click on the price and it shows an actor selector that will accept the price.
- [ ] End to end test


### Refactor Market

 - [ ] User chooses a demand and offer market model
 - [ ] We pass to Market.new the list of name and market model and it generates the actors itsef
    - [ ] Show theoritical result with price and quantity
    - [ ] Refine the way we calculate WT, it does not work

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
