/** @type {import('next').NextConfig} */
const nextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  images: {
    unoptimized: true,
  },
  // Enable standalone output for Docker
  output: 'standalone',
  // Experimental features for better performance
  experimental: {
    serverComponentsExternalPackages: ['@aws-sdk/client-s3'],
  },
}

export default nextConfig
