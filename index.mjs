import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);

const [accAlice, accBob] = await stdlib.newTestAccounts(2, startingBalance);
console.log("Hello, Alice and Bob!");

console.log("Launching...");
const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

const HAND = ["Rock", "Paper", "Scissors"];
const OUTCOME = ["Bob wins", "Draw", "Alice wins"];

const Player = (who) => ({
  getHand: () => {
    const hand = Math.floor(Math.random() * 3);
    console.log(`${who} gets ${HAND[hand]}`);
    return hand;
  },
  seeOutcome: (outcome) => {
    console.log(`${who} sees ${OUTCOME[outcome]}`);
  },
});

console.log("Starting backends...");
await Promise.all([
  backend.Alice(ctcAlice, {
    ...stdlib.hasRandom,
    ...Player("Alice"),
  }),
  backend.Bob(ctcBob, {
    ...stdlib.hasRandom,
    ...Player("Bob"),
  }),
]);

console.log("Goodbye, Alice and Bob!");
