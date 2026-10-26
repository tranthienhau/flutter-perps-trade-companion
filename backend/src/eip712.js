export const domain = {
  name: 'Exchange',
  version: '1',
  chainId: 42161,
  verifyingContract: '0x0000000000000000000000000000000000000000',
};

/** Signed ONCE by the user's main wallet: registers the agent key. */
export const approveAgentTypes = {
  ApproveAgent: [
    { name: 'agent', type: 'address' },
    { name: 'agentName', type: 'string' },
    { name: 'builder', type: 'address' },
    { name: 'validUntil', type: 'uint64' },
    { name: 'nonce', type: 'uint64' },
  ],
};

/** Signed by the agent key for every open / close. No transfer or withdraw field exists. */
export const tradeIntentTypes = {
  TradeIntent: [
    { name: 'account', type: 'address' },
    { name: 'asset', type: 'uint32' },
    { name: 'isBuy', type: 'bool' },
    { name: 'size', type: 'string' },
    { name: 'limitPx', type: 'string' },
    { name: 'triggerPx', type: 'string' },
    { name: 'reduceOnly', type: 'bool' },
    { name: 'nonce', type: 'uint64' },
  ],
};

export const ASSETS = { BTC: 0, ETH: 1, SOL: 2 };
