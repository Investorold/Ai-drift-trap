import os
from web3 import Web3
from openai import OpenAI
from dotenv import load_dotenv
from eth_account import Account

# Load environment variables from .env file
load_dotenv()

# --- Configuration ---
# Blockchain RPC URL (e.g., Sepolia, Hoodi testnet)
RPC_URL = os.getenv("RPC_URL")
# Your private key (ensure this is handled securely, e.g., via environment variables)
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
# Address of your deployed ChatGPTInfoStore contract
CHATGPT_INFO_STORE_ADDRESS = os.getenv("CHATGPT_INFO_STORE_ADDRESS")
# OpenAI API Key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# --- Web3 Setup ---
w3 = Web3(Web3.HTTPProvider(RPC_URL))
if not w3.is_connected():
    print("Failed to connect to Web3 provider!")
    exit()

# Your account
account = Account.from_key(PRIVATE_KEY)
w3.eth.default_account = account.address

print(f"Connected to blockchain. Account: {account.address}")

CHATGPT_INFO_STORE_ABI = [
  {
    "type": "constructor",
    "inputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "encodedChatGPTInfo",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "updateInfo",
    "inputs": [
      {
        "name": "_newInfo",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "ChatGPTInfoUpdated",
    "inputs": [
      {
        "name": "newInfo",
        "type": "string",
        "indexed": False,
        "internalType": "string"
      }
    ],
    "anonymous": False
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": True,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": True,
        "internalType": "address"
      }
    ],
    "anonymous": False
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  }
]

chatgpt_info_store_contract = w3.eth.contract(
    address=CHATGPT_INFO_STORE_ADDRESS,
    abi=CHATGPT_INFO_STORE_ABI
)

# --- OpenAI Setup ---
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# --- Main Logic ---
def get_chatgpt_response(prompt_text: str) -> str:
    try:
        # Using the Chat Completions API (can be switched to Responses API if needed)
        response = openai_client.chat.completions.create(
            model="gpt-3.5-turbo", # Or "gpt-4", "gpt-4o", etc.
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": prompt_text}
            ]
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Error getting ChatGPT response: {e}")
        return ""

def encode_response_for_onchain(response_text: str) -> str:
    # This is where you'll implement your encoding logic.
    # For now, we'll just return the first 100 characters or the full text if shorter.
    # In a real scenario, you might encode sentiment, keywords, a hash, etc.
    if len(response_text) > 100:
        return response_text[:100] + "..."
    return response_text

def update_onchain_info(encoded_info: str):
    print(f"Attempting to update on-chain info with: {encoded_info}")
    try:
        # Build the transaction
        transaction = chatgpt_info_store_contract.functions.updateInfo(encoded_info).build_transaction({
            'from': account.address,
            'nonce': w3.eth.get_transaction_count(account.address),
            'gas': 200000, # Adjust gas limit as needed
            'gasPrice': w3.eth.gas_price # Or use w3.to_wei('gwei', 'gas_price_in_gwei')
        })

        # Sign the transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, private_key=PRIVATE_KEY)

        # Send the transaction
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        print(f"Transaction sent. Tx Hash: {tx_hash.hex()}")

        # Wait for the transaction to be mined
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"Transaction mined. Status: {receipt.status}")
        if receipt.status == 1:
            print("On-chain info updated successfully!")
        else:
            print("Transaction failed!")

    except Exception as e:
        print(f"Error updating on-chain info: {e}")

if __name__ == "__main__":
    # Example usage:
    prompt = "Summarize the main benefits of blockchain technology in one sentence."
    chatgpt_text = get_chatgpt_response(prompt)

    if chatgpt_text:
        encoded_data = encode_response_for_onchain(chatgpt_text)
        update_onchain_info(encoded_data)
    else:
        print("Could not get a response from ChatGPT.")

    print("Script finished.")
