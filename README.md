# Ecosim

Ecosim is a website that provides economic simulators for high school teachers and students. It's a work in progress.


## Next TODO

- [ ] Design simulation page in market_live: sim component
- [x] Add accept action in the market_live.ex file.
- [x] Add button undo last action
- [x] Disable form for price when no price.
- [x] Display events in reverse order.
- [x] List of participants should not have person who make a transaction. This should be filtered with
the period's actor list.
- [x] Add a button to manually add a period
- [x] Add result
    - [x] Graph as the one found in the 1962 article
- [x] Extract common UI interface from the one_for_all_mode_live into a market_components
- [ ] Improve sim action buttons

### Bug
- [ ] When displaying a transaction, sometimes a buyer is said to have sold something to a seller. We need
to display the correct actor order depending on the actor's type.
- [ ] When Adding a period, it should reset the list of actions
- [ ] When clicking on a period, it should show the period


## Roadmap

1. Create the mode Multi
2. Create the mode One user with bots
3. Improve market simulator with tax
4. Improve market simulator with monopole
5. Add simulator bank and monetary creation, credits make deposits
6. Add simulator on inflation

## Author

Emmanuel Guefif
