"use client";

import React, { useMemo, useState, useCallback, useEffect } from "react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Image from "next/image";
import { RPS_ABI } from "@/lib/abis/rps-abi";
import { ContractFunctionParameters } from "viem";
import {
  Transaction,
  TransactionButton,
} from "@coinbase/onchainkit/transaction";
import { useChainId, useReadContract, useAccount } from "wagmi";
import { Badge } from "@/components/ui/badge";
import { getMoveName } from "@/lib/helper";
import { ADDRESS_RPS } from "@/lib/token-address";

export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const chainId = useChainId();
  const { address } = useAccount();
  const [resolvedParams, setResolvedParams] = useState<{ id: string } | null>(
    null
  );
  const [selectedMove, setSelectedMove] = useState<number | null>(null);

  useEffect(() => {
    params.then(setResolvedParams);
  }, [params]);

  const id = resolvedParams?.id;

  const { data: gameData, refetch: refetchGameData } = useReadContract({
    address: ADDRESS_RPS,
    abi: RPS_ABI,
    functionName: "games",
    args: id ? [BigInt(id)] : undefined,
    query: {
      enabled: !!id,
      refetchInterval: 5000,
    },
  });

  const parsedGameData = useMemo(() => {
    if (!gameData) return null;

    const [player1, player2, move1, move2, status, winner] = gameData as [
      string, // player1
      string, // player2
      number, // move1
      number, // move2
      number, // status
      string // winner
    ];

    return {
      player1,
      player2,
      move1,
      move2,
      status,
      winner,
    };
  }, [gameData]);
  //game result -> WIN || DRAW || LOSE
  const gameResult = useMemo(() => {
    if (!parsedGameData || !address) return null;

    const { winner, status } = parsedGameData;

    if (status !== 2) return null;

    if (winner.toLowerCase() === address.toLowerCase()) {
      return "WIN";
    } else if (winner === "0x0000000000000000000000000000000000000000") {
      return "DRAW";
    } else {
      return "LOSE";
    }
  }, [parsedGameData, address]);

  // Move options: 1 = Rock, 2 = Paper, 3 = Scissors
  const moves = [
    { id: 1, name: "Rock", image: "/rock.png" },
    { id: 2, name: "Paper", image: "/paper.png" },
    { id: 3, name: "Scissors", image: "/scissors.png" },
  ];

  const handleRandomMove = useCallback(() => {
    const randomMove = Math.floor(Math.random() * 3) + 1;
    setSelectedMove(randomMove);
  }, []);

  const submitMoveContracts = useMemo(
    () =>
      (!id || selectedMove === null
        ? []
        : [
            {
              address: ADDRESS_RPS,
              abi: RPS_ABI,
              functionName: "submitMove",
              args: [BigInt(id), selectedMove],
            },
          ]) as unknown as ContractFunctionParameters[],
    [id, selectedMove]
  );

  const redeemContracts = useMemo(
    () =>
      (!id || gameResult !== "WIN"
        ? []
        : [
            {
              address: ADDRESS_RPS,
              abi: RPS_ABI,
              functionName: "redeemVictoryNFT",
              args: [BigInt(id), process.env.NEXT_PUBLIC_PINATA_CID],
            },
          ]) as unknown as ContractFunctionParameters[],
    [id, gameResult]
  );

  const onRedeemSuccess = useCallback(() => {
    refetchGameData();
  }, [refetchGameData]);

  const onMoveSuccess = useCallback(() => {
    setSelectedMove(null);
    refetchGameData();
  }, [refetchGameData]);

  return (
    <div className="flex flex-col py-6 px-4 items-center justify-center min-h-[calc(100vh-80px)] gap-6 bg-blue-100 w-full">
      <div className="text-center">
        <h1 className="text-2xl font-bold mb-2">Game Room #{id}</h1>
        {(!parsedGameData || parsedGameData.status !== 2) && (
          <p className="text-gray-600">Choose your move!</p>
        )}
      </div>

      {parsedGameData && (
        <Card className="w-full">
          <CardHeader>
            <CardTitle className="text-center">Game Status</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="font-medium text-gray-600">Player 1:</p>
                <p className="font-mono text-xs">{`${parsedGameData.player1.slice(
                  0,
                  6
                )}...${parsedGameData.player1.slice(-4)}`}</p>
                <p className="text-gray-600">
                  Move: {getMoveName(parsedGameData.move1)}
                </p>
              </div>
              <div>
                <p className="font-medium text-gray-600">Player 2:</p>
                <p className="font-mono text-xs">{`${parsedGameData.player2.slice(
                  0,
                  6
                )}...${parsedGameData.player2.slice(-4)}`}</p>
                <p className="text-gray-600">
                  Move: {getMoveName(parsedGameData.move2)}
                </p>
              </div>
            </div>

            <div className="text-center pt-4 border-t">
              <p className="text-sm text-gray-600">
                Status:
                <span className="ml-1 font-medium">
                  {parsedGameData.status === 0
                    ? "Waiting for Player"
                    : parsedGameData.status === 1
                    ? "In Progress"
                    : "Finished"}
                </span>
              </p>

              {parsedGameData.status === 2 && (
                <div className="mt-2">
                  <p className="text-sm text-gray-600">Winner:</p>
                  <p className="font-mono text-xs">{parsedGameData.winner}</p>
                </div>
              )}
            </div>

            {gameResult && (
              <Badge className="flex items-center justify-center bg-white">
                <div className="inline-flex items-center px-4 py-2 rounded-full text-lg font-bold">
                  {gameResult === "WIN"
                    ? "🎉 YOU WIN!"
                    : gameResult === "LOSE"
                    ? "😔 YOU LOSE!"
                    : "🤝 DRAW!"}
                </div>
              </Badge>
            )}

            {gameResult === "WIN" && (
              <div className="pt-4 border-t">
                <Button asChild className="w-full bg-white">
                  <Transaction
                    calls={redeemContracts}
                    chainId={chainId}
                    onSuccess={onRedeemSuccess}
                  >
                    <TransactionButton
                      className="bg-transparent opacity-100 hover:bg-transparent active:bg-transparent"
                      text="🏆 Claim Victory NFT"
                    />
                  </Transaction>
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {(!parsedGameData || parsedGameData.status !== 2) && (
        <>
          <div className="grid grid-cols-2 gap-4 mt-6">
            {moves.map((move) => (
              <Card
                key={move.id}
                className={`w-32 h-32 rounded-full cursor-pointer transition-all hover:scale-105 ${
                  selectedMove === move.id
                    ? "ring-4 bg-blue-50 text-black"
                    : "hover:bg-blue-200 text-black"
                }`}
                onClick={() => setSelectedMove(move.id)}
              >
                <CardContent className="flex items-center justify-center h-full p-4">
                  <div className="text-center">
                    <Image
                      src={move.image}
                      alt={move.name}
                      width={50}
                      height={50}
                      className="mx-auto mb-2"
                    />
                    <p className="text-sm font-medium">{move.name}</p>
                  </div>
                </CardContent>
              </Card>
            ))}

            <Card
              className={`w-32 h-32 rounded-full cursor-pointer transition-all hover:scale-105 ${
                selectedMove &&
                selectedMove >= 1 &&
                selectedMove <= 3 &&
                !moves.find((m) => m.id === selectedMove)
                  ? "ring-4 bg-blue-50 text-black"
                  : "hover:bg-blue-200 text-black"
              }`}
              onClick={handleRandomMove}
            >
              <CardContent className="flex items-center justify-center h-full p-4">
                <div className="text-center">
                  <Image
                    src="/random.svg"
                    alt="random"
                    width={50}
                    height={50}
                    className="mx-auto mb-2"
                  />
                  <p className="text-sm font-medium">Random</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {selectedMove && (
            <div className="text-center">
              <p className="mb-4 text-lg">
                Selected:{" "}
                <span className="font-bold">
                  {moves.find((m) => m.id === selectedMove)?.name ||
                    `Move ${selectedMove}`}
                </span>
              </p>

              <Button asChild disabled={!selectedMove}>
                <Transaction
                  calls={submitMoveContracts}
                  chainId={chainId}
                  onSuccess={onMoveSuccess}
                >
                  <TransactionButton
                    className="bg-transparent opacity-100 hover:bg-transparent active:bg-transparent"
                    text="Submit Move"
                  />
                </Transaction>
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
