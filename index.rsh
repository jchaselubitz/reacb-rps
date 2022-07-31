"reach 0.1";

const Player = {
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => {
  const A = Participant("Alice", {
    ...Player,
  });
  const B = Participant("Bob", {
    ...Player,
  });
  init();

  A.only(() => {
    const handAlice = declassify(interact.getHand());
  });
  A.publish(handAlice);
  commit();

  B.only(() => {
    const handBob = declassify(interact.getHand());
  });
  B.publish(handBob);

  const outcome = (handAlice + (4 - handBob)) % 3;
  commit();

  each([A, B], () => {
    interact.seeOutcome(outcome);
  });

  exit();
});
