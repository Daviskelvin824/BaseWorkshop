// @noErrors: 2307 2580 2339 - cannot find 'process', cannot find './wagmi', cannot find 'import.meta'
"use client";

import type { ReactNode } from "react";
import { OnchainKitProvider } from "@coinbase/onchainkit";
import { baseSepolia } from "wagmi/chains"; // add baseSepolia for testing
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { wagmiConfig } from "@/lib/wagmi";

export function Providers(props: { children: ReactNode }) {
  const queryClient = new QueryClient();
  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <OnchainKitProvider
          apiKey={process.env.NEXT_PUBLIC_ONCHAINKIT_API_KEY}
          chain={baseSepolia}
          config={{
            appearance: {
              mode: "auto",
            },
          }}
        >
          {props.children}
        </OnchainKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
