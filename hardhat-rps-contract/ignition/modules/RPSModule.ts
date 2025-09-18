import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("RPSModule", (m) => {
  // Deploy the RockPaperScissors contract
  const rps = m.contract("RockPaperScissors");

  return { rps };
});
