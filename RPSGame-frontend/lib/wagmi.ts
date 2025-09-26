// @noErrors: 2554
import { createConfig, http } from "wagmi";
import { baseSepolia } from "wagmi/chains";
import { coinbaseWallet } from "wagmi/connectors";

export const wagmiConfig = createConfig({
  chains: [baseSepolia],
  connectors: [
    coinbaseWallet({
      appName: "onchainkit",
    }),
  ],
  ssr: true,
  transports: {
    [baseSepolia.id]: http(`https://sepolia.base.org`),
  },
});
