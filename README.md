# Agora Stable Swap

Agora Stable Swap is designed to provide stablecoin swaps with low slippage for whitelisted addresses. This repository contains the smart contracts and related code for the protocol.

## Prerequisites

Before you begin, ensure you have met the following requirements:

- **Node.js**: You need to have [Node.js](https://nodejs.org/) installed.
- **npm**: Node.js package manager, which is installed with Node.js.
- **Git**: Required for cloning the repository [Git](https://git-scm.com/downloads).
- **Solidity Compiler**: Required for compiling smart contracts. You can use [Forge](https://book.getfoundry.sh/getting-started/installation) from the Foundry toolkit.

## Installation

To set up the project locally, follow these steps:

1. **Clone the repository**:
   ```bash
   gh repo clone agora-finance/agora-stable-swap-rc
   ```

2. **Navigate to the project directory**:
   ```bash
   cd agora-stable-swap-rc
   ```

3. **Install dependencies**:
   ```bash
   npm install
   ```

4. **Compile the contracts**:
   If you are using Hardhat, run:
   ```bash
   forge build
   ```

### Ecosystem Participants
![Ecosystem Particpants](docs/_images/ecosystem.jpg)

### Key Contracts and their inheritance
![Key Contracts and their inheritance](docs/_images/inheritance.jpg)

## Contract Layout

The `@agora-stable-swap` contracts are organized as follows:

```
agora-stable-swap/src/contracts/
│
├── agora-stable-swap-pair/
│   ├── AgoraCompoundingOracle.sol            # Price oracle implementation for stable pair pricing
│   ├── AgoraStableSwapAccessControl.sol      # Permission management and role-based access system
│   ├── AgoraStableSwapPair.sol               # Primary interface for stable pair interactions
│   ├── AgoraStableSwapPairCore.sol           # Core implementation of stable swap mechanics
│   └── AgoraStableSwapPairStorage.sol        # Pair state management and data structure definitions
│
├── agora-stable-swap-registry/
│   ├── AgoraStableSwapRegistry.sol           # Centralized registry for managing whitelisted pairs
│   └── AgoraStableSwapRegistryStorage.sol    # Registry state management and data structure definitions
│
├── interfaces/
│   ├── IAgoraStableSwapPair.sol              # External interface specifications for stable pair
│   └── IUniswapV2Callee.sol                  # Callback interface for Uniswap V2 compatibility
│
├── proxy/
    ├── AgoraProxyAdmin.sol                   # Administrative control for proxy operations
    └── AgoraTransparentUpgradeableProxy.sol  # Transparent proxy pattern implementation
```

