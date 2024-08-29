require('dotenv').config();
const { ethers, Wallet } = require('ethers');

const privateKey = process.env.PRIVATE_KEY;

if (!privateKey) {
  throw new Error('Private key is not set');
}

const wallet = new Wallet(privateKey);

const domain = {
  name: 'HCGBalancePool',
  version: '1',
  chainId: 11155111, // Replace with your network's ID
  verifyingContract: process.env.POOL_ADDRESS, // Replace with your contract's address
};

const types = {
  withdrawTokens: [
    { name: 'amount', type: 'uint256' },
    { name: 'token', type: 'address' },
    { name: 'to', type: 'address' },
    { name: 'nonce', type: 'uint256' },
    { name: 'deadline', type: 'uint256' },
  ],
};

async function signWithdrawal(amount, address) {
  const amountInWei = ethers.parseEther(amount.toString());
  console.log('------>', amountInWei);

  const nonce = Math.floor(Math.random() * 10) + Date.now();

  const currentTimeInSeconds = Math.floor(Date.now() / 1000);
  const oneHourLater = currentTimeInSeconds + 3600; // 1 hour from now

  const value = {
    amount: amountInWei.toString(),
    token: process.env.TOKEN_ADDRESS, // Replace with the token's address
    to: address, // Replace with the recipient's address
    nonce: nonce, // Use the correct nonce
    deadline: oneHourLater, // 1 hour from now
  };

  const signature = await wallet.signTypedData(domain, types, value);

  console.log('Signature:', signature);
  console.log('Value:', value);

  const withdrawPayload = {
    signature,
    ...value,
  };

  console.log('Withdraw Payload:', withdrawPayload);
}

// Example usage
signWithdrawal(1, '0xd5b4FACFef52Be594F9E4B6d91f1923Ba514fA57'); // Replace with the desired amount and recipient address
