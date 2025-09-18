import { network } from "hardhat";
import { decodeEventLog } from "viem";

async function main() {
  const { viem } = await network.connect();
  const [alice, bob] = await viem.getWalletClients();
  const publicClient = await viem.getPublicClient();

  // Deploy the RockPaperScissors contract
  const rps = await viem.deployContract("RockPaperScissors");
  console.log("✅ Deployed RPS at:", rps.address);

  // Alice creates a game
  await rps.write.createGame({ account: alice.account });

  // Read latest gameId from contract
  const gameId = await rps.read.gameCounter();
  console.log("🎮 Game created with ID:", gameId.toString());

  // Bob joins the game
  await rps.write.joinGame([gameId], { account: bob.account });
  console.log("👥 Bob joined game", gameId.toString());

  // Alice = Paper (2), Bob = Rock (1)
  await rps.write.submitMove([gameId, 2], { account: alice.account });
  console.log("📝 Alice played Paper");

  await rps.write.submitMove([gameId, 1], { account: bob.account });
  console.log("📝 Bob played Rock");

  // Check winner
  const game = await rps.read.getGame([gameId]);
  console.log("🏆 Winner:", game.winner);

  // Redeem NFT for the winner
  const uri = "ipfs://victory1";
  const txHash = await rps.write.redeemVictoryNFT([gameId, uri], {
    account: alice.account,
  });

  // Wait for receipt
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  // Find Transfer event (ERC721 mint)
  const transferLog = receipt.logs.find((log) => {
    try {
      const decoded = decodeEventLog({
        abi: rps.abi,
        data: log.data,
        topics: log.topics,
      });
      return decoded.eventName === "Transfer";
    } catch {
      return false;
    }
  });

  if (!transferLog) throw new Error("No Transfer event found in logs");

  // Decode the Transfer log
  const decoded = decodeEventLog({
    abi: rps.abi,
    data: transferLog.data,
    topics: transferLog.topics,
  });

  // Narrow type by checking eventName
  if (decoded.eventName !== "Transfer") {
    throw new Error("Expected Transfer event but got " + decoded.eventName);
  }

  // Now TS knows it's the Transfer event
  const tokenId = (
    decoded.args as { from: string; to: string; tokenId: bigint }
  ).tokenId;

  console.log("🪙 NFT minted with ID:", tokenId.toString());

  // Fetch tokenURI
  const tokenURI = await rps.read.tokenURI([tokenId]);
  console.log("📜 tokenURI:", tokenURI);
}

main().catch((err) => {
  console.error("❌ Script failed:", err);
  process.exit(1);
});
