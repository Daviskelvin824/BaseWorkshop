"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RPS_ABI } from "@/lib/abis/rps-abi";
import {
  Transaction,
  TransactionButton,
} from "@coinbase/onchainkit/transaction";
import { useCallback, useMemo, useState } from "react";
import { ContractFunctionParameters } from "viem";
import { useChainId, useReadContract, useReadContracts } from "wagmi";
import { useRouter } from "next/navigation";
import { decodeEventLog } from "viem";
import { ADDRESS_RPS } from "@/lib/token-address";
import Image from "next/image";

export default function App() {
  const chainId = useChainId();
  const router = useRouter();
  const [joinId, setJoinId] = useState<string>("");
  const [page, setPage] = useState<number>(1);
  const pageSize = 4;

  const createGameContracts = useMemo(
    () =>
      [
        {
          address: ADDRESS_RPS,
          abi: RPS_ABI,
          functionName: "createGame",
          args: [],
        },
      ] as unknown as ContractFunctionParameters[],
    []
  );

  const { data: gameCounter } = useReadContract({
    address: ADDRESS_RPS,
    abi: RPS_ABI,
    functionName: "gameCounter",
  });

  const joinGameContracts = useMemo(
    () =>
      (!joinId
        ? []
        : [
            {
              address: ADDRESS_RPS,
              abi: RPS_ABI,
              functionName: "joinGame",
              args: [BigInt(joinId)],
            },
          ]) as unknown as ContractFunctionParameters[],
    [joinId]
  );

  const onSuccessJoin = useCallback(() => {
    router.push(`room/${joinId}`);
  }, [joinId, router]);

  const onSuccessCreate = useCallback(
    (response: any) => {
      if (response?.transactionReceipts?.[0]) {
        const receipt = response.transactionReceipts[0];
        const gameCreatedLog = receipt.logs?.find((log: any) => {
          try {
            const decoded = decodeEventLog({
              abi: RPS_ABI,
              data: log.data,
              topics: log.topics,
            });
            return decoded.eventName === "GameCreated";
          } catch {
            return false;
          }
        });

        if (gameCreatedLog) {
          try {
            const decoded = decodeEventLog({
              abi: RPS_ABI,
              data: gameCreatedLog.data,
              topics: gameCreatedLog.topics,
            });

            if (decoded.eventName === "GameCreated" && decoded.args) {
              const gameId = (decoded.args as any).gameId;
              router.push(`room/${gameId.toString()}`);
            }
          } catch (error) {
            console.error("Error decoding GameCreated event:", error);
          }
        }
      }
    },
    [router]
  );

  // Build calls for all games
  const allGameCalls = useMemo(() => {
    if (!gameCounter) return [];
    const total = Number(gameCounter);
    return Array.from({ length: total }, (_, i) => ({
      address: ADDRESS_RPS,
      abi: RPS_ABI,
      functionName: "getGame",
      args: [BigInt(i + 1)],
    }));
  }, [gameCounter]);

  // Fetch all games
  const { data: allGames } = useReadContracts({
    contracts: allGameCalls,
  });

  // Filter only "Waiting" games (status = 0)
  const waitingGames = useMemo(() => {
    if (!allGames) return [];
    return allGames
      .map((g, i) => {
        if (!g?.result) return null;
        return { id: i + 1, ...(g.result as any) };
      })
      .filter((game) => game && Number(game.status) === 0);
  }, [allGames]);

  // Pagination
  const totalPages = Math.ceil(waitingGames.length / pageSize);
  const paginatedGames = waitingGames.slice(
    (page - 1) * pageSize,
    page * pageSize
  );

  const formatAddress = (addr: string) => {
    return addr === "0x0000000000000000000000000000000000000000"
      ? "Empty"
      : `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <div className="flex flex-col px-4 items-center min-h-[calc(100vh-80px)] gap-3 bg-blue-100">
      <Image
        src={"/rps-logo.png"}
        alt="logo"
        width={200}
        height={200}
        className="cursor-pointer z-50"
      />

      {/* Create Game Button */}
      <Button asChild>
        <Transaction
          calls={createGameContracts}
          chainId={chainId}
          onSuccess={onSuccessCreate}
        >
          <TransactionButton
            className="bg-transparent opacity-100 hover:bg-transparent active:bg-transparent"
            text={"Create Game"}
          />
        </Transaction>
      </Button>

      {/* Join Game Dialog */}
      <Dialog>
        <DialogTrigger asChild>
          <Button variant={"neutral"} className="w-full">
            Join Game
          </Button>
        </DialogTrigger>
        <DialogContent className="sm:max-w-[425px] bg-blue-100">
          <DialogHeader>
            <DialogTitle>Join Room</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <p>Total Games: {gameCounter?.toString() ?? "0"}</p>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="gameId" className="text-right">
                Game ID
              </Label>
              <Input
                value={joinId}
                id="gameId"
                className="col-span-3"
                type="number"
                onChange={(e) => setJoinId(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button asChild>
              <Transaction
                calls={joinGameContracts}
                chainId={chainId}
                onSuccess={onSuccessJoin}
              >
                <TransactionButton
                  className="bg-transparent opacity-100 hover:bg-transparent active:bg-transparent"
                  text={"Join Game"}
                />
              </Transaction>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Waiting Rooms Section */}
      <div className="w-full mt-5">
        <h1 className="text-2xl text-left mb-3">Waiting Rooms</h1>
        {paginatedGames.length === 0 ? (
          <p className="text-gray-600">No waiting games right now.</p>
        ) : (
          <div className="grid grid-cols-2 gap-4">
            {paginatedGames.map((game) => (
              <Card
                key={game.id}
                className="rounded-2xl shadow-md hover:shadow-lg transition"
              >
                <CardHeader>
                  <CardTitle className="text-black">Game #{game.id}</CardTitle>
                </CardHeader>
                <CardContent className="flex flex-col gap-2">
                  <p className="text-sm">
                    <strong>Player1:</strong> {formatAddress(game.player1)}
                  </p>
                  <p className="text-sm">
                    <strong>Player2:</strong> {formatAddress(game.player2)}
                  </p>
                  <Button
                    onClick={() => router.push(`room/${game.id}`)}
                    variant={"neutral"}
                    className="w-full bg-blue-100 text-black"
                  >
                    View Room
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* Pagination Controls */}
        {totalPages > 1 && (
          <div className="flex justify-center gap-4 my-4">
            <Button disabled={page === 1} onClick={() => setPage((p) => p - 1)}>
              Prev
            </Button>
            <span className="self-center">
              Page {page} of {totalPages}
            </span>
            <Button
              disabled={page === totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
