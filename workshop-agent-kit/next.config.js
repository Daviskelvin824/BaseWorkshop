/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  eslint: {
    ignoreDuringBuilds: true, // <- this disables ESLint checks during build
  },
};

module.exports = nextConfig;
