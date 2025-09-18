import assert from "node:assert/strict";
import { describe, it, beforeEach } from "node:test";
import { network } from "hardhat";
import { getAddress, parseEventLogs } from "viem";

describe("RockPaperScissors Game", async () => {
  const { viem } = await network.connect();
  const publicClient = await viem.getPublicClient();

  let rps: any;
  let alice: any;
  let bob: any;

  beforeEach(async () => {
    // ambil wallet signer dari hardhat
    const [signerAlice, signerBob] = await viem.getWalletClients();
    alice = signerAlice;
    bob = signerBob;

    // deploy contract
    rps = await viem.deployContract("RockPaperScissors");
  });

  async function createGameBy(player: any) {
    const txHash = await rps.write.createGame([], { account: player.account });
    const receipt = await publicClient.waitForTransactionReceipt({
      hash: txHash,
    });
    const logs = parseEventLogs({
      abi: rps.abi,
      logs: receipt.logs,
      eventName: "GameCreated",
    });
    return (logs[0] as any).args.gameId as bigint;
  }

  it("Alice should be able to create a game", async () => {
    const gameId = await createGameBy(alice);
    const game = await rps.read.getGame([gameId]);

    assert.equal(getAddress(game.player1), getAddress(alice.account.address));
    assert.equal(Number(game.status), 0, "status must be Waiting");
  });

  it("Bob should be able to join Alice's game", async () => {
    const gameId = await createGameBy(alice);

    await rps.write.joinGame([gameId], { account: bob.account });

    const game = await rps.read.getGame([gameId]);
    assert.equal(getAddress(game.player2), getAddress(bob.account.address));
    assert.equal(Number(game.status), 1, "status must be Ongoing");
  });

  it("Alice (Rock) vs Bob (Scissors) => Alice wins", async () => {
    const gameId = await createGameBy(alice);
    await rps.write.joinGame([gameId], { account: bob.account });

    await rps.write.submitMove([gameId, 1], { account: alice.account }); // Rock = 1
    await rps.write.submitMove([gameId, 3], { account: bob.account }); // Scissors = 3

    const game = await rps.read.getGame([gameId]);
    assert.equal(getAddress(game.winner), getAddress(alice.account.address));
    assert.equal(Number(game.status), 2, "status must be Finished");
  });

  it("Draw game (Rock vs Rock)", async () => {
    const gameId = await createGameBy(alice);
    await rps.write.joinGame([gameId], { account: bob.account });

    await rps.write.submitMove([gameId, 1], { account: alice.account }); // Rock
    await rps.write.submitMove([gameId, 1], { account: bob.account }); // Rock

    const game = await rps.read.getGame([gameId]);
    assert.equal(game.winner, "0x0000000000000000000000000000000000000000");
    assert.equal(Number(game.status), 2, "status must be Finished");
  });

  it("Winner can redeem NFT with URI", async () => {
    const gameId = await createGameBy(alice);
    await rps.write.joinGame([gameId], { account: bob.account });

    await rps.write.submitMove([gameId, 2], { account: alice.account }); // Paper = 2
    await rps.write.submitMove([gameId, 1], { account: bob.account }); // Rock = 1

    const uri = "ipfs://victory1";
    const txHash = await rps.write.redeemVictoryNFT([gameId, uri], {
      account: alice.account,
    });

    const receipt = await publicClient.waitForTransactionReceipt({
      hash: txHash,
    });
    const logs = parseEventLogs({
      abi: rps.abi,
      logs: receipt.logs,
      eventName: "NFTRedeemed",
    });
    const tokenId = (logs[0] as any).args.tokenId as bigint;

    assert.equal(
      getAddress(await rps.read.ownerOf([tokenId])),
      getAddress(alice.account.address)
    );
    assert.equal(await rps.read.tokenURI([tokenId]), uri);
  });

  it("Should revert if non-winner tries to redeem NFT", async () => {
    const gameId = await createGameBy(alice);
    await rps.write.joinGame([gameId], { account: bob.account });

    await rps.write.submitMove([gameId, 1], { account: alice.account }); // Rock
    await rps.write.submitMove([gameId, 2], { account: bob.account }); // Paper => Bob wins

    await assert.rejects(
      rps.write.redeemVictoryNFT([gameId, "ipfs://fail"], {
        account: alice.account,
      }),
      /NotWinner/
    );
  });

  it("Should revert if game is not finished", async () => {
    const gameId = await createGameBy(alice);
    await rps.write.joinGame([gameId], { account: bob.account });

    await rps.write.submitMove([gameId, 1], { account: alice.account }); // only Alice moves

    await assert.rejects(
      rps.write.redeemVictoryNFT([gameId, "ipfs://fail"], {
        account: alice.account,
      }),
      /GameNotOngoing/
    );
  });
});
