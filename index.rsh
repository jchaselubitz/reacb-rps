"reach 0.1";

const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (handAlice, handBob) => (handAlice + (4 - handBob)) % 3;

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, (handAlice) =>
  forall(UInt, (handBob) => assert(isOutcome(winner(handAlice, handBob))))
);
forall(UInt, (hand) => assert(winner(hand, hand) == DRAW));

const Player = {
  ...hasRandom,
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const A = Participant("Alice", {
    ...Player,
    wager: UInt,
    deadline: UInt, // time delta (blocks/rounds)
  });
  const B = Participant("Bob", {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  init();

  const informTimeout = () => {
    each([A, B], () => {
      interact.informTimeout();
    });
  };

  A.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  A.publish(wager, deadline).pay(wager);
  commit();

  B.only(() => {
    interact.acceptWager(wager);
  });
  B.pay(wager).timeout(relativeTime(deadline), () => closeTo(A, informTimeout));

  var outcome = DRAW;
  invariant(balance() == 2 * wager && isOutcome(outcome));
  while (outcome == DRAW) {
    commit();

    A.only(() => {
      const _handAlice = interact.getHand();
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
      const commitAlice = declassify(_commitAlice);
    });
    A.publish(commitAlice).timeout(relativeTime(deadline), () =>
      closeTo(B, informTimeout)
    );
    commit();

    unknowable(B, A(_handAlice, _saltAlice));
    B.only(() => {
      const handBob = declassify(interact.getHand());
    });
    B.publish(handBob).timeout(relativeTime(deadline), () =>
      closeTo(A, informTimeout)
    );
    commit();

    A.only(() => {
      const saltAlice = declassify(_saltAlice);
      const handAlice = declassify(_handAlice);
    });
    A.publish(saltAlice, handAlice).timeout(relativeTime(deadline), () =>
      closeTo(B, informTimeout)
    );
    checkCommitment(commitAlice, saltAlice, handAlice);

    outcome = winner(handAlice, handBob);
    continue;
  }
  assert(outcome == A_WINS || outcome == B_WINS);
  transfer(2 * wager).to(outcome == A_WINS ? A : B);
  commit();

  each([A, B], () => {
    interact.seeOutcome(outcome);
  });
});
