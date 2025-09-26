export const getMoveName = (moveId: number) => {
  const moveNames = { 0: "None", 1: "Rock", 2: "Paper", 3: "Scissors" };
  return moveNames[moveId as keyof typeof moveNames] || "Unknown";
};
